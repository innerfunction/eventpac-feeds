var mods = {
	df: 	require('dateformat'),
	path:	require('path'),
	tt:		require('semo/lib/tinytemper')
}
var utils = require('semo/eventpac/utils');
var eputils = require('../eputils');
var settings = require('./general');
var imageSettings = require('./images-settings');

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

function gradientProperty( styles ) {
    for (var idx in styles) {
        var style = styles[idx];
        if ( typeof style.backgroundColor == "object") {
            var color1 = style.backgroundColor[0],
                color2 = style.backgroundColor[1] || color1;
            style.backgroundColor = 'linear-gradient(to right, '+ color1 +' , '+ color2 +');'+
            'background: -moz-linear-gradient(left, '+color1+' 0%, '+color2+' 100%); '+
            'background: -webkit-gradient(linear, left top, right top, color-stop(0%, '+color1+'), color-stop(100%,'+color2+')); '+
            'background: -webkit-linear-gradient(left, '+color1+' 0%,'+color2+' 100%); '+
            'background: -o-linear-gradient(left, '+color1+' 0%,'+color2+' 100%); '+
            'background: -ms-linear-gradient(left, '+color1+' 0%,'+color2+' 100%); '+
            'background: linear-gradient(to right, '+color1+' 0%,'+color2+' 100%); '+
            'filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='+color1+', endColorstr='+color2+',GradientType=1 );'; 
        }                 
    }
    return styles;
}

var feed = {
    active: false,
    name: settings.name,
    opts: {
        exts: {
            uriSchemes: eputils.schemes(settings.name)
        }
    },
    types: {
        events: function( post ) {
            var occurrence = post.occurrences[0];
            return {
                id:             post.id,
                title:          post.title,
                occurrences:    post.occurrences,
                startDate:      mods.df( post.occurrences.startDateTime, 'dddd, mmmm dS'), //h:MM TT, mmmm dS, yyyy
                startTime:      mods.df( post.occurrences.startDateTime, 'HH:MM'),
                endDate:        mods.df( post.occurrences.endDateTime, 'dddd, mmmm dS'),
                endTime:        mods.df( post.occurrences.endDateTime, 'HH:MM'),
                content:        post.content,
                performer:      post.performers,
                image:          post.photo,
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
        style: {
            depends: '',
            build: function( cx ) {
                var appImages = settings.appImages;
                var imageInfo = imageSettings;
                    console.log(imageInfo);
                for (var key in images) {
                    console.log("debug .....................................");
                    console.log(key);

                    var imageProperties = imageInfo[key];
                    console.log(imageProperties);
               
                    var image = cx.images( appImages[key] );
                    for (var idx in imageProperties) {
                        var newImage = imageProperties[idx] ;
                        if (key =='splashScreen' ){
                            console.log(newImage.filename + " ..... height: " + newImage.height);
                        }
                        //console.log(imageProperties[indx].width +", " + imageProperties[indx].height +", " + imageProperties[indx].filename);
                        image.resize({height: newImage.height, format: 'png' }, newImage.filename+'.{format}' );
                    }
                    
                }

            }
        },
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
                cx.eval('template.html', updates, 'event-{id}.html');
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
                cx.eval('template.html', updates, 'speaker-{id}.html');
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

