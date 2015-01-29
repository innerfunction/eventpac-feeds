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
                pos:            post.id,
                title:          post.title,
                points:         post.points,
                nationality:    post.nationality,
                type:			'resultsTeam'
            }
        },
        performers: function( post ) {
            var group = (post.group && post.group[0])||{};
            return {
                id:				'resultsIndividual-'+post.id,	
                pos:            post.id,
                title:          post.title,
                nationality:    post.nationality,
                team:           group.title||'',
                teamInitials:	group.teamInitials,
                points:         post.points,
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
            }
        },
        results: {
            depends: '*',
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
                cx.eval('templates/all-results.html', results, 'results.html');
            }
        },
        meta: {
            depends: ['news','events'],
            build: function( cx, updatesByType ) {

                var newsUpdates = updatesByType.news, newsFiles;
                if( newsUpdates ) {
                    newsFiles = cx.eval('templates/news-detail.html', newsUpdates.filter( isPublished ), 'news-{id}.html');
                }

                var updates = [];
                for( var type in updatesByType ) {	

                    if( type == 'results' || type == 'resultsIndividual' || type == 'resultsTeam') continue;
                    
                    var typeUpdates = updatesByType[type].filter( isPublished );
                    var thumbnailURLs = typeUpdates.map(function getImage( post ) {
                        return post.thumbnail;
                    })
                    .filter(function hasURL( url ) {
                        return !!url;
                    });
                    var thumbnails = cx.images( thumbnailURLs );
                    thumbnails.resize({ width: 100, format: 'jpeg' },'{name}-{width}.{format}' ).mapTo( typeUpdates, 'thumbnail');

                    typeUpdates = typeUpdates.map(function map( post ) {

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
module.exports = require('../inc-build').extend( feed, module );
