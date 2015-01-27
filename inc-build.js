var Log = require('log4js').getLogger('inc-build');
var mods = {
    path: require('path')
}

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
        // Download the post URL and map using the type specific map function.
        var post = cx.get( url )
        .posts(function( data ) {
            return data.posts
        })
        .map(function map( post ) {
            var status = post.status;
            var typeMap = feed.postTypes[post.type];
            if( typeMap ) {
                post = typeMap( post );
            }
            post.status = status;
            cx.applyBuildScope( post );
            return post;
        });
        // Write the post to the db.
        cx.write( post );
        // Clean non-published posts from the db.
        cx.clean(function clean( post ) {
            // Delete posts which aren't published or aren't in the current build scope.
            return post.status == 'publish' || cx.hasCurrentBuildScope( post );
        });
    }

    // Perform an incremental build. This function will first generate separate lists of
    // update posts for each post type. It will then generate a list of build targets
    // dependent on the updated post types, and then invoke each target.
    function build( cx ) {
        // Get the current build object.
        var build = cx.build();
        // Decide whether to do a full or incremental build.
        var fullBuildEvery = feed.fullBuildEvery||10;
        var doFullBuild = (build.seq % fullBuildEvery) == 0;
        if( doFullBuild ) {
            Log.debug('Full build of feed %s (%d/%d)', feed.id, build.seq, fullBuildEvery );
        }
        // Copy files from last build; or use feed's base content if not previous build.
        if( !doFullBuild && build.prevBuild ) {
            var path = mods.path.resolve( build.prevBuild.paths.content() );
            Log.debug('Copying previous build from %s', path );
            cx.file( path+'/.' ).cp();
        }
        else {
            Log.debug('Copying base content');
            cx.file('base/.').cp();
        }
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
            var updates = result[post.type];
            if( updates ) {
                updates.push( post );
            }
            else {
                result[post.type] = [ post ];
            }
            return result;
        }, {});
        // Generate list of updated post types
        var updatedTypes = Object.keys( updatesByType );
        // Generate list of build targets dependent on updated post types
        var targets = getDependentTargetsForPostTypes( updatedTypes, dependencies, targets );
        // The build function result - updated posts to be written to the db section of the build meta.
        var posts = {};
        // Invoke each build target
        targets.forEach(function each( target ) {
            try {
                Log.debug('Building target %s/%s', feed.id, target.id );
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
                Log.error('Building target %s of feed %s', target.id, feed.id, e );
            }
        });
        return { db: { posts: posts } };
    }
    var _exports = {
        active:         feed.active||false,
        queue:          feed.queue,
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
