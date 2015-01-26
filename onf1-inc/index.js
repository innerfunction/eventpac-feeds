var mods = {
	df: 	require('dateformat'),
	path:	require('path'),
	tt:		require('semo/lib/tinytemper')
}
var format = require('util').format;
var utils = require('semo/eventpac/utils');
var eputils = require('../eputils');

function isPublished( post ) {
    return post.status == 'published';
}

var feed = {
    active: true,
    opts: {
        exts: {
            uriSchemes: eputils.schemes('onf1')
        }
    },
    postTypes: {
        groupperformers: function( post ) {
            return {
                id:				'resultsTeam-'+post.id,
                pos:            post.id,
                title:          post.title,
                points:         post.points,
                nationality:    post.nationality,
                type:			'resultsTeam',
                downloadTime:   downloadTime
            }
        },
        performers: function( post ) {
            return {
                id:				'resultsIndividual-'+post.id,	
                pos:            post.id,
                title:          post.title,
                nationality:    post.nationality,
                team:           post.group[0].title||'',
                teamInitials:	post.group[0].teamInitials,
                points:         post.points,
                type:			'resultsIndividual',
                downloadTime:   downloadTime
            }
        },
        events: function( post ) {
            // Reduce the occurrences array to a map of occurrences
            // keyed by name.
            var occurrences = post.occurrences
            .reduce(function( result, occur ) {
                result[occur.occurrenceName] = occur;
                return result;
            }, {});
            // Get GP and Race occurrence.
            var gpOcc = occurrences.GP;
            var raceOcc = occurrences.Race||gpOcc;
            // Generate result.
            return {
                id:                         post.id,
                status:                     post.status,
                title:                      utils.filterHTML( post.title ),
                content:                    utils.filterContent( post.content ),
                image:                      post.photo,
                thumbnail:                  post.photo,
                circuit:                    post.circuit,
                location:                   utils.cuval( post.locations ),
                
                start:                      mods.df( gpOcc.startDateTime, 'dd/mm/yyyy'),
                end:                        mods.df( gpOcc.endDateTime, 'dd/mm/yyyy'),
                startTime:                  raceOcc.startDateTime,
                endTime:                    raceOcc.endDateTime,

                laps:                       post.laps,
                distance:                   post.distance,
                longitude:                  post.longitude,
                fastestLap:                 post.fastestLap,
                fastestLapDriver:           post.fastestLapDriver,
                fastestLapTime:             post.fastestLapTime,
                fastestLapCarYear:          post.fastestLapCarYear,
                individualResults:          post.individualResults,
                teamResults:                post.teamResults,
                turnNumber:			        post.turnNumber,
                throttleLapUsePercentaje:	post.throttleLapUsePercentaje,
                importantLaps:		        post.importantLaps,
                type:				        'events',
                downloadTime:               downloadTime
            }
        },
        post: function( post ) {
            return {
                id:             post.id,
                title:          post.title,
                author:         post.author,
                modified:       post.modifiedDateTime,
                created:        post.createdDateTime,
                content:        post.content,
                image:          post.photo,
                thumbnail:      post.photo,
                type:		    'news',
                downloadTime:   downloadTime
            }
        }
    },
    targets: {
        images: {
            depends: '*',
            build: function( cx, updatesByType ) {

                var publishedUpdates = Object.keys( updatesByType )
                .reduce(function( result, type ) {
                    return result.concat( updatesByType[type] );
                }, [])
                .filter( isPublished );

                var imageURLs = publishedUpdates.map(function getImage( post ) {
                    return post.status == 'publish' && post.image;
                })
                .filter(function hasURL( url ) {
                    return !!url;
                });

                var images = cx.images( imageURLs );
                images.resize({ width: 100, format: 'jpeg' },'{name}-{width}.{format}' ).mapTo( publishedUpdates, 'thumbnail');
                images.resize({ width: 500, format: 'jpeg' }, true ).mapTo( publishedUpdates, 'image');
            }
        },
        events: {
            depends: 'events',
            build: function( cx, updatesByType ) {
                var eventUpdates = updatesByType.events;
                cx.eval('templates/events.html', eventUpdates.filter( isPublished ), 'events-{id}.html');
            }
        },
        results: {
            depends: '*',
            build: function( cx, updatesByType ) {
                var resultsIndividual = cx.data.posts.filter(function indivResult( post ) {
                    return post.type == 'resultsIndividual' && post.status == 'published';
                });
                var resultsTeam = cx.data.posts.filter(function teamResult( post ) {
                    return post.type == 'resultsTeam' && post.status == 'published';
                });
                var results = {
                        resultsIndividual:  resultsIndividual,
                        resultsTeam:        resultsTeam
                    };
                cx.eval('templates/all-results.html', results, 'results.html');
            }
        },
        meta: {
            depends: ['news','events'],
            build: function( cx, updatesByType ) {

                var newsUpdates = updatesByType.news, newsFiles;
                if( newsUpdates ) {
                    newsFiles = cx.eval('templates/news-detail.html', updatesByType.news.filter( isPublished ), 'news-{id}.html');
                }

                var updates = [];

                for( var type in postsByType ) {	

                    if( type == 'results' || type == 'resultsIndividual' || type == 'resultsTeam') continue;
                    
                    var typeUpdates = postsByType[type].map(function( post ) {
                        var description, action;
                        switch( post.type ) {
                        case 'news':
                            description = post.author+' '+post.modified;
                            var file = newsFiles.get( post.id );
                            if( file ) {
                                action = eputils.action('DefaultWebView', { html: file.uri('subs') });
                            }
                            break;
                        case 'events':
                            description = post.circuit;
                            action = eputils.action('EventDetail', { eventID: post.id });
                            break;
                        }
                        var thumbnail;
                        if( post.thumbnail ) {
                            thumbnail = post.thumbnail.uri('@subs');
                        }
                        return {
                            id:				post.id,
                            type:			post.type,
                            title:			post.title,
                            description:	description,
                            image:			thumbnail,
                            action:			action,
                            startTime:		post.startTime,
                            endTime:		post.end,
                            modifiedTime:   post.modified
                        }
                    });
                    updates = updates.concat( typeUpdates );
                }
                return updates;
            }
        }
    }
}
require('../inc-build').extend( feed, module );
