var Log = require('log4js').getLogger('inc-build');
var mods = {
    path: require('path')
}
var format = require('util').format;

// Format of the URL for fetching all posts in a feed.
var AllPostsURLFormat = 'http://%s.eventpac.com/api/%s/all-posts';

/**
 * Return an object mapping post types to lists of dependent target IDs.
 * @param targets   A map of build targets, keyed by target ID.
 */
function mapTargetDependencies( targets ) {
    // Dependencies will be mapped as post type onto an array of target IDs.
    var dependencies = {};
    for( var targetID in targets ) {
        var target = targets[targetID];
        // Copy the target ID onto the target.
        target.id = targetID;
        // Target depends can be specified as an array or as a single value, so coerce to an
        // array; if no depends is given then default to the wildcard.
        var depends = Array.isArray( target.depends ) ? target.depends : [ target.depends||'*' ];
        depends.forEach(function each( type ) {
            var targets = dependencies[type];
            if( targets ) {
                targets.push( targetID );
            }
            else {
                targets = [ targetID ];
            }
            dependencies[type] = targets;
        });
    }
    return dependencies;
}

/**
 * Return a list of build targets dependent on a list of post types.
 * @param postTypes     An array of post types.
 * @param dependencies  A map of post type -> build target dependencies.
 * @param targets       A map of target ID -> build target.
 * @return An array of dependent build targets.
 */
function getDependentTargetsForPostTypes( postTypes, dependencies, targets ) {
    // Add wildcard (all types) if not already on list.
    // This is to match targets that declare their dependency as '*' (everything).
    if( postTypes.indexOf('*') < 0 ) {
        postTypes = postTypes.concat('*');
    }
    return postTypes.reduce(function reduce( result, type ) {
        var targetIDs = dependencies[type];                 // Get list of targetIDs for the current type.
        if( targetIDs ) {
            targetIDs.forEach(function each( targetID ) {   // Add target ID to result if not already on list.
                if( result.indexOf( targetID ) < 0 ) {
                    result.push( targetID );
                }
            });
        }
        return result;
    }, [])
    .map(function map( targetID ) { // Map target IDs to the target instance.
        return targets[targetID];
    });
}

/**
 * Usage: module.exports = require('inc-build').extend( feed, module )
 */
exports.extend = function( feed, _module ) {

    // Read build targets and organize by post type dependencies.
    var targets = feed.targets||{};
    var dependencies = mapTargetDependencies( targets );

    // Perform an incremental download. This function will download a post from the
    // specified URL before passing it to a type-specific map function provided by
    // the feed, and then writing it to the database. Each downloaded post also has
    // the current build scope (i.e. the ID of the last performed build for the
    // current feed) applied to it.
    // Note that deleted posts are kept in the database for one build cycle, then
    // deleted.
    function download( cx, url ) {
        // If no URL is specified then download all posts.
        if( !url ) {
            url = format( AllPostsURLFormat, feed.name, feed.name );
        }
        // Download the post URL and map using the type specific map function.
        var post = cx.get( url )
        .posts(function( data ) {
            Log.debug('Downloaded %s posts for feed %s', data.posts && data.posts.length, feed.name );
            return data.posts
        })
        .map(function map( post ) {
            try {
                var $status = post.status;
                var $type = post.postType;
                var typeMap = feed.types[$type];
                if( typeMap ) {
                    post = typeMap( post );
                }
                post.$status = $status;
                post.$type = $type;
                cx.applyBuildScope( post );
                return post;
            }
            catch( e ) {
                Log.error('Failed to map post %s (%s) of feed %s', post.id, post.postType, feed.name, e );
            }
            return false; // Return false to indicate no data due to error.
        });
        // Write the post to the db.
        cx.write( post );
        // Write the feed record (this to save the last download time and current build scope).
        cx.record( cx.applyBuildScope({}) );
        // Clean non-published posts from the db.
        cx.clean(function clean( post ) {
            // Delete posts which aren't published or aren't in the current build scope.
            return post.$status == 'publish' || cx.hasCurrentBuildScope( post );
        });
    }

    // Perform an incremental build. This function will first generate separate lists of
    // update posts for each post type. It will then generate a list of build targets
    // dependent on the updated post types, and then invoke each target.
    function build( cx ) {
        var feedID = this.feed.id; // 'this' is a Build instance.
        // Get the current build object.
        var build = cx.build();
        // Decide whether to do a full or incremental build.
        var fullBuildEvery = feed.fullBuildEvery||10;
        var doFullBuild = (build.seq % fullBuildEvery) == 0;
        if( doFullBuild ) {
            Log.info('Full build of feed %s (%d/%d)', feedID, build.seq, fullBuildEvery );
        }
        // Copy files from last build if any.
        if( !doFullBuild && build.prevBuild ) {
            var path = mods.path.resolve( build.prevBuild.paths.content() );
            Log.debug('Copying previous build from %s', path );
            cx.file( path+'/.' ).cp();
        }
        // Copy base content.
        Log.debug('Copying base content');
        cx.file('base/*').cp();
        // Generate list of posts in current build scope
        var updates;
        if( doFullBuild ) {
            updates = cx.data.posts;
        }
        else {
            updates = cx.data.posts.filter( cx.hasCurrentBuildScope );
        }
        // Organize list of posts by type
        var updatesByType = updates.reduce(function reduce( result, post ) {
            var updates = result[post.$type];
            if( updates ) {
                updates.push( post );
            }
            else {
                result[post.$type] = [ post ];
            }
            return result;
        }, {});
        // Generate list of updated post types
        var updatedTypes = Object.keys( updatesByType );
        // Generate list of build targets dependent on updated post types
        var buildTargets = getDependentTargetsForPostTypes( updatedTypes, dependencies, targets );
        // The build function result - updated posts to be written to the db section of the build meta.
        var posts = {};
        // Try resolving posts from the previous build.
        var prevBuild = build.prevBuild;
        if( prevBuild ) {
            // If previous build found then copy its posts.
            var prevPosts = prevBuild.db.posts;
            for( var id in prevPosts ) {
                posts[id] = prevPosts[id];
            }
        }
        // Invoke each build target
        buildTargets.forEach(function each( target ) {
            try {
                Log.debug('Building target %s/%s', feedID, target.id );
                var result = target.build( cx, updatesByType );
                // Copy results into posts.
                if( result ) {
                    posts = result.reduce(function reduce( posts, record ) {
                        posts[record.id] = record;
                        return posts;
                    }, posts );
                }
            }
            catch( e ) {
                Log.error('Failed to build target %s of feed %s', target.id, feedID, e );
            }
        });
        // Automatically add newly deleted posts to the db manifest.
        /*
        updatedTypes.forEach(function eachType( type ) {
            var delcount = 0;
            updatesByType[type].forEach(function eachPost( post ) {
                if( post.status == 'trash' ) {
                    posts[post.id] = null;
                    delcount++;
                }
            });
            if( delcount ) {
                Log.debug('Found %d newly deleted %s posts in feed %s', delcount, type, feedID );
            }
        });
        */
        cx.data.posts.forEach(function eachPost( post ) {
            // Mark any trash post as deleted in the manifest.
            // (Note: This will result in a list of *all* deleted posts).
            if( post.status == 'trash' ) {
                posts[post.id] = null;
            }
        });
        // Return the db manifest.
        return { db: { posts: posts } };
    }
    var _exports = {
        active:         feed.active||false,
        queue:          feed.name,
        fullBuildEvery: feed.fullBuildEvery,
        download:       download,
        build:          build
    }
    for( var id in feed.opts ) {
        _exports[id] = feed.opts[id];
    }
    _exports.inPath = require('path').dirname( _module.filename );
    return _exports;
}
