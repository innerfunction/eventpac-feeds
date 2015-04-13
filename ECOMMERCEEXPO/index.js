var mods = {
    ch:     require('cheerio'),
	df: 	require('dateformat'),
	path:	require('path'),
	tt:		require('semo/lib/tinytemper')
};
var utils = require('semo/eventpac/utils');
var eputils = require('../eputils');
var settings = require('./settings');

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

function formatHTML( html ) {
    return html
    .split(/<br \/>/g)
    .filter(function filter( s ) { return s.length > 0; })
    .reduce(function reduce( html, p ) {
        return html+'<p>'+p+'</p>';
    },'');
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
        page: function( post) {
            return {
                id:         post.id,
                title:      post.title,
                status:     post.status,
                content:    formatHTML( post.content )
            }
        },
        events: function( post ) {
            var occurrence = post.occurrences[0];
            var timeMarker  = (settings.timeShape == 'circle' ) ? ' <br/> ' : '';
            return {
                id:             post.id,
                title:          post.title,
                occurrences:    post.occurrences,
                date: {
                    startDate:      mods.df( occurrence.startDateTime, 'dddd, mmmm dS'), /*h:MM TT, mmmm dS, yyyy*/
                    endDate:        mods.df( occurrence.endDateTime, 'dddd, mmmm dS')
                },
                time: {
                    startTime:      mods.df( occurrence.startDateTime, 'HH:MM') +timeMarker ,
                    endTime:        timeMarker + mods.df( occurrence.endDateTime, 'HH:MM')
                },
                description:    mods.df( occurrence.startDateTime, 'HH:MM') + ' - ' + mods.df( occurrence.endDateTime, 'HH:MM'),
                status:         post.status,
                startTime:      occurrence.startDateTime,
                endTime:        occurrence.endDateTime,
                content:        formatHTML( post.content ),
                performer:      post.performers,
                image:          post.photo,
                type:           'events',
                shape:          settings.timeShape
            }
        },
        speakers: function( post ) {
            var banner = (settings.imageShape == "banner") ? true : false;
            return {
                id:                 post.id,
                title:              post.title,
                content:            formatHTML( post.content ),
                company:            post.company,
                shortDescription:   post.shortDescription,
                linkedinURL:        post.linkedinUrl,
                status:             post.status,
                image:              post.photo,
                type:               'speakers',
                shape:              settings.imageShape,
                banner:             banner
            }
        }
    },
    targets: {
        page: {
            depends: "page",
            build: function(cx, updatesByType) {
                /*
                var updates = updatesByType.page.map(function map( post ) {
                    return {
                        id:         post.id,
                        title:      post.title,
                        content:    post.content
                    }
                });
                buildImages( cx, updates );
                for (var idx in updates) {
                    var post = updates[idx];
                    cx.eval('template.html', post, 'page-'+post.id+'.html');
                }
                */
                updatesByType.page.forEach(function each( update ) {
                    if( update.id == '46' ) {
                        // Convert the exhibitor page to a JSON list.
                        // First load the page's html.
                        var $ = mods.ch.load( update.content );
                        var items = $('a').map(function map() {
                            var $a = $(this);
                            var src= $a.find('img').attr('src');
                            return {
                                href:   $a.attr('href'),
                                image:  src
                            }
                        }).get();
                        // Extract image srcs.
                        var srcs = items.map(function map( item ) { return item.image; });
                        // Download and resize images.
                        var images = cx.images( srcs );
                        images.resize({ height: 100, format: 'jpeg' }, true ).mapTo( items, 'image' );
                        // Generate the JSON.
                        var data = items.map(function map( item ) {
                            return {
                                accessory:               'DisclosureIndicator',
                                action:                  item.href,
                                backgroundImage:         item.image.uri('@subs'),
                                selectedBackgroundImage: item.image.uri('@subs'),
                                height:                  100
                            }
                        });
                        cx.json( data, 'exhibitors.json', true );
                    }
                    else {
                        cx.eval('template.html', update, 'page-{id}.html');
                    }
                });
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
                        date:           post.date,
                        time:           post.time,
                        startTime:      post.startTime,
                        endTime:        post.endTime,
                        description:    post.description,
                        action:         eputils.action('EventDetail', { 'eventID': post.id }),
                        image:          post.image,
                        content:        post.content,
                        shape:          post.shape
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
                        action:         post.action,
                    }
                });
            }
        },
        speakers: {
            depends: 'speakers',
            build: function( cx, updatesByType ) {
                var updates = updatesByType.speakers.map(function map( post ) {
                    return {
                        id:                 post.id,
                        type:               post.type,
                        title:              post.title,
                        description:        post.title,
                        shortDescription:   post.shortDescription,
                        company:            post.company,
                        linkedinURL:        post.linkedinURL,
                        action:             eputils.action('SpeakerDetail', { 'speakerID': post.id }),
                        image:              post.image,
                        content:            post.content,
                        shape:              post.shape,
                        banner:             post.banner
                    }
                });
                buildImages( cx, updates );
                cx.eval('template.html', updates, 'speaker-{id}.html');
                return updates.map(function update( post ) {
                    return {
                        id:             post.id,
                        type:           post.type,
                        title:          post.title,
                        description:    post.company,
                        action:         post.action,
                    }
                });
            }
        }
    }
}

module.exports = require('../inc-build').extend( feed, module );
