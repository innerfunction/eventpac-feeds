var mods = {
	df: 	require('dateformat'),
	path:	require('path'),
	tt:		require('semo/lib/tinytemper')
}
var utils = require('semo/eventpac/utils');
var eputils = require('../eputils');
var settings = require('./general');

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
    active: false,
    name: settings.appName,
    opts: {
        exts: {
            uriSchemes: eputils.schemes(settings.appName)
        }
    },
    types: {
        events: function( post ) {
            var occurrence = post.occurrences[0];
            return {
                id:             post.id,
                title:          post.title,
                occurrences:    post.occurrences,
                startDate:      mods.df( occurrence.startDateTime, 'dddd, mmmm dS'), //h:MM TT, mmmm dS, yyyy
                startTime:      mods.df( occurrence.startDateTime, 'HH:MM'),
                endDate:        mods.df( occurrence.endDateTime, 'dddd, mmmm dS'),
                endTime:        mods.df( occurrence.endDateTime, 'HH:MM'),
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
                    var occurrence = post.occurrences[0];
                    return {
                        id:             post.id,
                        type:           post.type,
                        title:          post.title,
                        description:    post.title,
                        startTime:      post.startTime,
                        endTime:        post.endTime,
                        action:         eputils.action('EventDetail', { 'eventID': post.id }),
                        image:          post.image,
                        content:        post.content
                    }
                });
                buildImages( cx, updates );
                cx.eval('templates.html', updates, 'event-{id}.html');
                return updates.map(function update( post ) {
                    return {
                        id:             post.id,
                        type:           post.type,
                        title:          post.title,
                        description:    post.description,
                        startTime:      post.startTime,
                        endTime:        post.endTime,
                        action:         post.action
                    }
                });
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
                cx.eval('templates.html', updates, 'speaker-{id}.html');
                return updates.map(function update( post ) {
                    return {
                        id:             post.id,
                        type:           post.type,
                        title:          post.title,
                        description:    post.description,
                        action:         post.action
                    }
                });
            }
        }
    }
}
module.exports = require('../inc-build').extend( feed, module );

