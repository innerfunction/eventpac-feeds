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

    var postsByType = types.reduce(function( posts, type ) {
        posts[type] = cx.data.posts.filter(function(post) {
            return post.type == type;
        });
    });
}
exports.inpath = require('path').dirname(module.filename);
