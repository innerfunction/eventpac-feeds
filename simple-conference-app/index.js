var mods = {
    df:     require('dateformat'),
    path:   require('path'),
    tt:     requite('semo/lib/tinytemper')
};
var format =    require('util').format;
var utils =     require('semo/eventpac/utils');
var eputils =   require('../eputils');

var thumbnailWidth = 100,
    imageWidth = 500;
var thumbnailFormat = 'jpeg',
    imageFormat = 'jpeg';

var feedName = 'SimpleConferenceApp'
function isPublished ( post ) {
    return post.status == 'publish';
}

function mapImages( cx, updates ) {
    var imageURLs = updates.map(function getImage(post) {
        return post.images;
    })
    .filter(function hasURL( url ) {
        return !!url;
    });

    var images = cx.images( imageURLs );
    images.resize({ width: thumbnailWidth, format: thumbnailFormat}, '{name}-{width}.{format}').mapTo( updates, 'thumbnail' );
    images.resize({ width: imageWidth, format: imageFormat }, true ).mapTo( updates, 'image');
}

var feed = {
    active: true,
    name: feedName,
    opts: { },

    types: {},
    targets: {}
}
module.exports = require('../inc-build').extend( feed, module );
