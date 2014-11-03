var mods = {
	df: 	require('dateformat'),
	path:	require('path'),
	tt:		require('semo/lib/tinytemper')
}
var utils = require('semo/eventpac/utils');
var eputils = require('../eputils');

exports.active = true;
//exports.schedule = '@hourly';
exports.schedule = { minute: [ 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55 ] };
exports.exts = {
    uriSchemes: eputils.schemes('onf1')
}

var BaseURL = 'http://onf1.com.mx/api/onf1/%s';

exports.download = function(cx) {

	cx.clean(function(post) {
		return !(post.id && post.id.indexOf('resultsIndividual.') == 0);
	});

    var downloadTime = new Date().toString();
    
	var resultsTeam = cx.get( BaseURL, 'results/groups' )
    .posts(function( data ) {
        return data.posts;
    })
    .map(function( post ) {
		return {
			id:				'resultsTeam-'+post.id,
			pos:            post.id,
        	title:          post.title,
        	points:         post.points,
        	nationality:    post.nationality,
			type:			'resultsTeam',
            downloadTime:   downloadTime
		}
    });

	var resultsIndividual = cx.get( BaseURL, 'results/performers' )
    .posts(function( data ) {
        return data.posts;
    })
    .map(function( post ) {
		return {
			id:				'resultsIndividual-'+post.id,	
			pos:            post.id,
			title:          post.title,
			nationality:    post.nationality,
			team:           post.group[0].title || '',
			teamInitials:	post.group[0].teamInitials,
			points:         post.points,
			type:			'resultsIndividual',
            downloadTime:   downloadTime
		}
    });
	
	var events = cx.get( BaseURL, 'events' )
    .posts(function( data ) {
        return data.posts;
    })
    .map(function( post ) {
        // Reduce the occurrences array to a map of occurrences
        // keyed by name.
        var occurrences = post.occurrences
        .reduce(function( result, occ ) {
            result[occ.occurrenceName] = occ;
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
    });

	var news = cx.get( BaseURL, 'news' )
    .posts(function( data ) {
        return data.posts;
    })
    .map(function( post ) {
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
    });

	cx.write(resultsIndividual);
	cx.write(resultsTeam);
	cx.write(events);
	cx.write(news);
    
    cx.clean(function( post ) {
        return post.downloadTime == downloadTime;
    });
}
exports.build = function(cx) {

	cx.file([
			'templates/theme/css/bootstrap.min.css',
        	'templates/theme/js/jquery.min.js',
        	'templates/theme/js/bootstrap.min.js',
       		'templates/theme/css/flags16.css',
       		'templates/theme/css/flags32.css',
       		'templates/css/style.css',
       		'templates/theme/css/font-awesome.css',
       		'templates/theme/images',
			'templates/images',
			'templates/about.html',
			'templates/share.html',
			'templates/twitter.html',
			'html/sponsor.html'
		]).cp();

	var types = ['news', 'events', 'resultsIndividual', 'resultsTeam'];
	
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
        images.resize( { width: 100, format: 'jpeg' }, '{name}-{width}.{format}' ).mapTo( posts[type], 'thumbnail' );
		images.resize( { width: 500, format: 'jpeg' }, true ).mapTo( posts[type], 'image' );
		return posts;
	}, {});

	postsByType['results'] = {
            resultsIndividual: postsByType.resultsIndividual,
            resultsTeam: postsByType.resultsTeam
        };
	var newsFiles = cx.eval('templates/news-detail.html', postsByType.news, 'news-{id}.html');
    cx.eval('templates/events.html', postsByType.events, 'events-{id}.html');
	cx.eval('templates/all-results.html', postsByType.results, 'results.html');

	var updates = [];

	for (var type in postsByType) {	

		if( type == 'results' || type == 'resultsIndividual' || type == 'resultsTeam') continue;
		
		var updatesForType = postsByType[type].map(function( post ) {
			var description, action;
			switch (post.type) {
				case 'news':
					description = post.author + ' ' + post.modified;
					var file = newsFiles.get( post.id );
					if( file ) {
                        action = eputils.action('DefaultWebView', { html: file.uri('subs') });
					}
					break;
				case 'events':
					description = post.circuit;
                    action = eputils.action('EventDetail', { 'eventID': post.id });
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
exports.inPath = require('path').dirname( module.filename );
