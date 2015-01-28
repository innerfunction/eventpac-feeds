var mods = {
	df: 	require('dateformat'),
	path:	require('path'),
	tt:		require('semo/lib/tinytemper')
}
var utils = require('semo/eventpac/utils');
var eputils = require('../eputils');

function isPublished( post ) {
    return post.status == 'published';
}

function buildImages( cx, updates ) {
    var imageURLs = updates.map(function map( post ) {
        return post.image;	
    })
    .filter(function( url ) {
        return !!url;
    });
    var images = cx.images( imageURLs );
    images.resize({ width: 500, format: 'jpeg' }, true ).mapTo( updates, 'image' );
}

var feed = {
    active: true,
    queue: 'nagp',
    opts: {
        exts: {
            uriSchemes: eputils.schemes('nagp')
        }
    },
    postTypes: {
        events: function( post ) {
            return {
                id:             post.id,
                title:          post.title,
                occurrences:    post.occurrences,
                startDate:      mods.df(post.occurrences[0].startDateTime, 'dddd, mmmm dS'), //h:MM TT, mmmm dS, yyyy
                startTime:      mods.df(post.occurrences[0].startDateTime, 'HH:MM'),
                endDate:        mods.df(post.occurrences[0].endDateTime, 'dddd, mmmm dS'),
                endTime:        mods.df(post.occurrences[0].endDateTime, 'HH:MM'),
                content:        post.content,
                performer:      post.performers,
                type:           post.postType
            }
        },
        performers: function( post ) {
            return {
                id:             post.id,
                title:          post.title,
                content:        post.content,
                image:          post.photo,
                type:           post.postType
            }
        }
    },
    targets: {
        events: {
            depends: 'events',
            build: function( cx, updatesByType ) {
                var updates = updatesByType.events.map(function map( post ) {
                    return {
                        id:             post.id,
                        type:           post.type,
                        title:          post.title,
                        description:    post.title,
                        startTime:      post.occurrences[0].startDateTime,
                        endTime:        post.occurrences[0].endDateTime,
                        action:         eputils.action('EventDetail', { 'eventID': post.id }),
                        image:          post.image,
                        content:        post.content
                    }
                });
                buildImages( cx, updates );
                cx.eval('templates/event-detail.html', updates, 'event-{id}.html');
                return updates;
            }
        },
        performers: {
            depends: 'performers',
            build: function( cx, updatesByType ) {
                var updates = updatesByType.performers.map(function map( post ) {
                    return {
                        id:             post.id,
                        type:           post.type,
                        title:          post.title,
                        description:    post.title,
                        action:         eputils.action('SpeakerDetail', { 'speakerID': post.id }),
                        image:          post.image,
                        content:        post.content
                    }
                });
                buildImages( cx, updates );
                cx.eval('templates/speaker-detail.html', updates, 'speaker-{id}.html');
                return updates;
            }
        }
    }
}
module.exports = require('../inc-build').extend( feed, module );
