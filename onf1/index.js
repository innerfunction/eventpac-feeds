var mods = {
	df: 	require('dateformat'),
	path:	require('path'),
	tt:		require('semo/lib/tinytemper')
}
var format = require('util').format;
var utils = require('semo/eventpac/utils');
var eputils = require('../eputils');

function isPublished( post ) {
    return post.status == 'publish';
}

function mapImages( cx, updates ) {

    var imageURLs = updates.map(function getImage( post ) {
        return post.image;
    })
    .filter(function hasURL( url ) {
        return !!url;
    });

    var images = cx.images( imageURLs );
    images.resize({ width: 100, format: 'jpeg' },'{name}-{width}.{format}' ).mapTo( updates, 'thumbnail');
    images.resize({ width: 500, format: 'jpeg' }, true ).mapTo( updates, 'image');
}

var feed = {
    active: true,
    name: 'onf1',
    opts: {
        exts: {
            uriSchemes: eputils.schemes('onf1')
        }
    },
    types: {
        groupperformers: function( post ) {
            return {
                id:				'resultsTeam-'+post.id,
                title:          post.title,
                points:         post.points,
                nationality:    post.nationality,
                status:         post.status,
                overallPosition: post.overallPosition,
                type:			'resultsTeam'
            }
        },
        performers: function( post ) {
            var group = (post.group && post.group[0])||{};
            return {
                id:				'resultsIndividual-'+post.id,	
                title:          post.title,
                nationality:    post.nationality,
                team:           group.title||'',
                teamInitials:	group.teamInitials,
                points:         post.points,
                status:         post.status,
                overallPosition: post.overallPosition,
                type:			'resultsIndividual'
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
                type:				        'events'
            }
        },
        post: function( post ) {
            return {
                id:             post.id,
                status:         post.status,
                title:          post.title,
                author:         post.author,
                modified:       post.modifiedDateTime,
                created:        post.createdDateTime,
                content:        post.content,
                image:          post.photo,
                thumbnail:      post.photo,
                type:		    'news'
            }
        }
    },
    targets: {
        events: {
            depends: 'events',
            build: function( cx, updatesByType ) {

                var updates = updatesByType.events.filter( isPublished );

                var imageURLs = updates.map(function getImage( post ) {
                    return post.image;
                })
                .filter(function hasURL( url ) {
                    return !!url;
                });

                var images = cx.images( imageURLs );
                images.resize({ width: 500, format: 'jpeg' }, true ).mapTo( updates, 'image');

                cx.eval('templates/events.html', updates, 'events-{id}.html');

                var thumbnailURLs = updates.map(function getImage( post ) {
                    return post.thumbnail;
                })
                .filter(function hasURL( url ) {
                    return !!url;
                });
                var thumbnails = cx.images( thumbnailURLs );
                thumbnails.resize({ width: 100, format: 'jpeg' },'{name}-{width}.{format}' ).mapTo( updates, 'thumbnail');

                updates = updates.map(function map( post ) {
                    return {
                        id:				post.id,
                        type:			post.type,
                        title:			post.title,
                        description:	post.circuit,
                        image:			post.thumbnail && post.thumbnail.uri('@subs'),
                        action:			eputils.action('EventDetail', { eventID: post.id }),
                        startTime:		post.startTime,
                        endTime:		post.end,
                        modifiedTime:   post.modified
                    }
                });

                return updates;
            }
        },
        news: {
            depends: 'post',
            build: function( cx, updatesByType ) {

                var updates = updatesByType.post.filter( isPublished );

                var imageURLs = updates.map(function getImage( post ) {
                    return post.image;
                })
                .filter(function hasURL( url ) {
                    return !!url;
                });

                var images = cx.images( imageURLs );
                images.resize({ width: 500, format: 'jpeg' }, true ).mapTo( updates, 'image');

                var newsFiles = cx.eval('templates/news-detail.html', updates, 'news-{id}.html');

                var thumbnailURLs = updates.map(function getImage( post ) {
                    return post.thumbnail;
                })
                .filter(function hasURL( url ) {
                    return !!url;
                });
                var thumbnails = cx.images( thumbnailURLs );
                thumbnails.resize({ width: 100, format: 'jpeg' },'{name}-{width}.{format}' ).mapTo( updates, 'thumbnail');

                updates = updates.map(function map( post ) {
                    var file = newsFiles.get( post.id ), action;
                    if( file ) {
                        action = eputils.action('DefaultWebView', { html: file.uri('subs') });
                    }
                    return {
                        id:				post.id,
                        type:			post.type,
                        title:			post.title,
                        description:	post.author+' '+post.modified,
                        image:			post.thumbnail && post.thumbnail.uri('@subs'),
                        action:			action,
                        startTime:		post.startTime,
                        endTime:		post.end,
                        modifiedTime:   post.modified
                    }
                });

                return updates;
            }
        },
        results: {
            depends: ['groupperformers','performers'],
            build: function( cx, updatesByType ) {
                var resultsIndividual = cx.data.posts.filter(function indivResult( post ) {
                    return post.type == 'resultsIndividual' && post.status == 'publish';
                });
                var resultsTeam = cx.data.posts.filter(function teamResult( post ) {
                    return post.type == 'resultsTeam' && post.status == 'publish';
                });
                var results = {
                    resultsIndividual:  resultsIndividual,
                    resultsTeam:        resultsTeam
                };
                for( var idx in results) {
                    results[idx] = results[idx].sort(function(obj1, obj2) {
                        return obj1.overallPosition - obj2.overallPosition;
                    });
                }
                cx.eval('templates/all-results.html', results, 'results.html');
            }
        }
    }
}
module.exports = require('../inc-build').extend( feed, module );
