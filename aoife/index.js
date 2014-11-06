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
            occurences:     post.occurences,
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
    
    /*
    var updates = [];

    for ( var type in postsByType ) {
        if (type == 'performers') continue;

        var updatesForType = postsByType[type].map(function( post ) {
            var description, action;

            switch (post.type) {
                case 'events':
                    description = post.title;
                    actions = eputils.action('EventDetail', { 'eventID': post.id });
                    break;
            }
            return {
                id:             post.id,
                type:           post.type,
                title:          post.title,
                description:    description,
                image:          post.image,
                action:         action
            }
        });
        updates = updates.concat( updatesForType );
    }*/
}
exports.inPath = require('path').dirname(module.filename);
