var mods = {
	df: 	require('dateformat'),
	path:	require('path'),
	tt:		require('semo/lib/tinytemper')
}
var utils = require('semo/eventpac/utils');

exports.active = true;
//exports.schedule = '@hourly';
exports.schedule = { minute: 52, second: 12 };
exports.download = function(cx) {

	var BaseURL = 'http://onf1.com.mx/api/onf1/%s';

	/*
		cx.get().posts('data.posts').map(...)
		cx.get().posts(function(data) { return data.posts }).map(...)
		cx.get().posts().map(...)
	*/

	/**
	 * Download a feed data
	 * 
	 * @param {string} BaseURL Base URL from where you want to download the feed
	 * @param {string} feed Feed name to add to the base URL
	 * @return {object} Returns a Feed object representing the downloaded data.
	 */
	var performers = cx.get( BaseURL, 'performers' )
    .posts()
    .map(function( post ) {
		return {
			id:             post.id,
       	    modified:       post.modified,
       	    title:          post.title,
       		nationality:    post.nationality,
			type:	        'performers'
       	}
	});

	var groups = cx.get( BaseURL, 'groups' )
    .posts()
    .map(function( post ) {
		return {
			id:             post.id,
       	   	status:         post.status,
           	modified:       post.modified,
           	title:          post.title,
           	nationality:    post.nationality,
			type:		    'groups'
		}
    });

	var resultsTeam = cx.get( BaseURL, 'results/groups' )
    .posts()
    .map(function( post ) {
		return {
			id:				'resultsTeam-'+post.id,
			pos:            post.id,            // Is the position
        	title:          post.title,
        	points:         post.points,
        	nationality:    post.nationality,
			type:			'resultsTeam'
		}
    });

	var resultsIndividual = cx.get( BaseURL, 'results/performers' )
    .posts()
    .map(function( post ) {
		return {
			id:				'resultsIndividual-'+post.id,	
			pos:            post.id,            // Is the position
			title:          post.title,
			nationality:    post.nationality,
			team:           post.group[0].title || '',
			teamInitials:	post.group[0].teamInitials,
			points:         post.points,
			type:			'resultsIndividual'
		}
    });
	
	var events = cx.get( BaseURL, 'events' )
    .posts()
    .map(function( post ) {
		return {
			id:         post.id,
			status:     post.status,
			modified:   post.modified,
			url:        post.url,    // The permalink url
            title:      utils.filterHTML( post.title ),
            content:    utils.filterContent( post.content ),
			image:      post.photo,
			circuit:    post.circuit,
			location:   utils.cuval( post.locations ),
			start:      post.startDateTime,
			end:        post.endDateTime,
			modified:   post.modifierDateTime,
			laps:               post.laps,
			distance:           post.distance,
			longitude:          post.longitude,
			fastestLap:         post.fastestLap,
			fastestLapDriver:   post.fastestLapDriver,
			fastestLapTime:     post.fastestLapTime,
			fastestLapCarYear:  post.fastestLapCarYear,
			individualResults:  post.individualResults,
			teamResults:        post.teamResults,
			turnNumber:			post.turnNumber,
			throttleLapUsePercentaje:	post.throttleLapUsePercentaje,
			importantLaps:		post.importantLaps,
			type:				'events',
		}
    });

	var news = cx.get( BaseURL, 'news' )
    .posts()
    .map(function( post ) {
		return {
			id:         post.id,
			status:     post.status,
			author:     post.author,
			modified:   post.modifiedDateTime,
			created:    post.createdDateTime,
			url:        post.url,       // The permalink url
			title:      post.title,
			content:    post.content,
			image:      post.photo,
			website:    post.website,        // A custom field to
			type:		'news',
		}
    });

	var pages = cx.get( BaseURL, 'pages' )
    .posts()
    .map(function( post ) {
		return {
			id:             post.id,
			modified:       post.modified,
			slug:           post.slug,
			url:            post.url,   // The permalink url
			title:          post.title,
			content:        post.content,
			attachments:    post.attachments,
			type:			'pages',
		}
    });	

	cx.write(performers);
	cx.write(groups);
	cx.write(resultsIndividual);
	cx.write(resultsTeam);
	cx.write(events);
	cx.write(news);
	cx.write(pages);
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
		cx.images( imageURLs, true ).mapTo( posts[type], 'image');
		return posts;
	}, {});

	postsByType['results'] = {resultsIndividual: postsByType.resultsIndividual, resultsTeam: postsByType.resultsTeam};
	cx.eval('templates/news-detail.html', postsByType.news, 'news-{id}.html');
	cx.eval('templates/event-detail.html', postsByType.events, 'events-{id}.html');
	cx.eval('templates/event-results.html', postsByType.events, 'event-results-{id}.html');
	cx.eval('templates/all-results.html', postsByType.results, 'results.html');

}
exports.inPath = require('path').dirname(module.filename);
