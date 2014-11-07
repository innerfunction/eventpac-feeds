var mods = {
	df: 	require('dateformat'),
	path:	require('path'),
	tt:		require('semo/lib/tinytemper')
}
var utils = require('semo/eventpac/utils');
var eputils = require('../eputils');

exports.active = true;

exports.schedule = { minute: [ 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55 ] };
exports.exts = {
    uriSchemes: eputils.schemes('aoife')
}

var BaseURL = 'http://aoife.eventpac.com/api/aoife/%s';

exports.download = function( cx ) {

    var events = cx.get( BaseURL, 'events' )
    .posts(function( data ) {
        return data.posts
    })
    .map(function( post ) {
        return {
            id:             post.id,
            title:          post.title,
            occurrences:    post.occurrences,
            startDate:      mods.df(post.occurrences.startDateTime, 'mmmm dS'), //h:MM TT, mmmm dS, yyyy
            startTime:      mods.df(post.occurrences.startDateTime, 'h:MM'),
            endDate:        mods.df(post.occurrences.endDateTime, 'mmmm dS'),
            endTime:        mods.df(post.occurrences.endDateTime, 'h:MM'),
            content:        post.content,
            type:           post.postType
        }
    });
    
    var performers = cx.get( BaseURL, 'performers' )
    .posts(function( data ) {
        return data.posts
    })
    .map(function( post ) {
        return {
            id:             post.id,
            title:          post.title,
            content:        post.content,
            type:           post.postType
        }
    });

    cx.write(events);
    cx.write(performers);
}
exports.build = function( cx ) {

    cx.file([
    'templates/images',
    'templates/css',
    'templates/theme',
    'templates/share.html',
    'templates/programme.html',
    'templates/contact.html'
    ]).cp();

    var types = ['events', 'performers'];

	var postsByType = types.reduce(function( posts, type ) {
		posts[type] = cx.data.posts.filter(function( post ) {
			return post.type == type;
		});

		var imageURLs = posts[type].map(function(post) {
			return post.image;	
		})
		.filter(function( url ) {
			return !!url;
		});
        var images = cx.images( imageURLs );
        //images.resize( { width: 100, format: 'jpeg' }, '{name}-{width}.{format}' ).mapTo( posts[type], 'thumbnail' );
		images.mapTo( posts[type], 'image' );
		return posts;
	}, {});
    var eventFiles = cx.eval('templates/event-detail.html', postsByType.events, 'event-{id}.html');
    cx.eval('templates/speaker-detail.html', postsByType.performers, 'speaker-{id}.html');
    
    
    var updates = [];

    for ( var type in postsByType ) {

        var updatesForType = postsByType[type].map(function( post ) {
            var description, action, startTime, endTime;

            switch (post.type) {
                case 'events':
                    description = post.title;
                    action = eputils.action('EventDetail', { 'eventID': post.id });
                    startTime = post.occurrences[0].startDateTime;
                    endTime = post.occurrences[0].endDateTime;
                    break;
                case 'performers':
                    description = post.title,
                    action = eputils.action('SpeakerDetail', { 'speakerID': post.id });
            }
            return {
                id:             post.id,
                type:           post.type,
                title:          post.title,
                description:    description,
                startTime:      startTime,
                endTime:        endTime,
                action:         action
            }
        });
        updates = updates.concat( updatesForType );
    }

        // Rewrite db update format to sets of per-table updates, keyed by record ID.
    var posts = updates
    .reduce(function( posts, record ) {
        posts[record.id] = record;
        return posts;
    }, {});
    // Return build meta data with db updates.
    return { db: { posts: posts } };
}
exports.inPath = require('path').dirname(module.filename);
