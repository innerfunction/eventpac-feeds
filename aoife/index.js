exports.active = true;

exports.schedule = { minute: 52, second: 12};
exports.exts = {
    uriSchemes: eputils.schemes('aoife')
}
exports.download = function( cx ) {
    var BaseURL = '';

    var events = cx.get( BaseURL, 'events' )
    .posts(function( data ) {
        return data.posts
    })
    .map(function( post ) {
        return {

        }
    });
    
    var events = cx.get( BaseURL, 'speakers' )
    .posts(function( data ) {
        return data.posts
    })
    .map(function( post ) {
        return {

        }
    });
}
exports.build = function( cx ) {

    cx.file([

    ]);

    var types = ['events', 'speakers'];

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

    var eventFiles = cx.eval('template/events-details.html', postsByType.events, 'events-{id}.html');
    cx.eval('template/speakers-details.html', postsByType.speakers, 'speakers-{id}.html');


}
exports.inpath = require('path').dirname(module.filename);
