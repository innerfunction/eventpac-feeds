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
    active: true,
    name: 'nslc2015',
    opts: {
        exts: {
            uriSchemes: eputils.schemes('nslc2015')
        }
    },
    types: {
        page: function( post) {
            return {
                id:         post.id,
                title:      post.title,
                status:     post.status,
                slug:       post.slug,
                content:    formatHTML( post.content )
            }
        },
        programme: function( post ) {
            var occurrence = post['event-date'];
            var timeMarker  = (settings.timeShape == 'circle' ) ? ' <br/> ' : '';
            return {
                id:             post.id,
                title:          post.title,
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
                type:           'programme',
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
        },
        exhibitors: function( post ) {
            return {
                id:                 post.id,
                type:               post.type,
                title:              post.title,
                content:            formatHTML( post.content ),
                status:             post.status,
                image:              post.photo,
                url:                post.exhibitorUrl
            }
        }
    },
    targets: {
        page: {
            depends: "page",
            build: function(cx, updatesByType) {
                var updates = updatesByType.page.map(function map( page ) {
                    var $ = mods.ch.load( page.content );
                    $('a').each(function each() {
                        var $a = $(this);
                        var href = $a.attr('href');
                        var text = $a.text();
                        var r = /^\s*@([\w-]+)\s+(.*)/.exec( text );
                        if( r ) {
                            var data = {
                                icon:   r[1],
                                url:    href,
                                title:  r[2]
                            }
                            var html = '<button class="social {icon}"><a href="{url}"><i class="fa fa-{icon}"></i>&nbsp;{title}</a></button>';
                            $a.replaceWith( $( mods.tt.eval( html, data ) ) );
                        }
                    });
                    page.content = $.html();
                    return page;
                });
                cx.eval('template.html', updates, 'page-{slug}.html');
            }
        },
        programme: {
            depends: 'programme',
            build: function( cx, updatesByType ) {
                var updates = updatesByType.programme.map(function map( post ) {
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
        },
        exhibitors: {
            depends: 'exhibitors',
            build: function( cx, updatesByType ) {
                // Complete exhibitors list.
                var exhibitors = cx.data.posts
                .filter(function filter( post ) {
                    return post.type == 'exhibitors';
                });
                // List images.
                var srcs = exhibitors.map(function map( exhib ) {
                    return exhib.image;
                });
                cx.images( srcs ).resize({ height: 100, format: 'png' }, true ).mapTo( exhibitors, 'image' );
                // List data.
                var data = exhibitors.map(function map( exhib ) {
                    return {
                        accessory:                  'DisclosureIndicator',
                        action:                     eputils.action('ExhibitorDetail', { 'exhibitorID': exhib.id }),
                        backgroundImage:            item.image.uri('@subs'),
                        selectedBackgroundImage:    item.image.uri('@subs'),
                        height:                     100
                    }
                });
                // List JSON.
                cx.json( data, 'exhibitors.json' );

                // Updated exhibitors.
                exhibitors = updatesByType.exhibitors;
                // Page images.
                buildImages( cx, exhibitors );
                // Build pages.
                cx.eval('template.html', exhibitors, 'exhibitor-{id}.html');
            }
        }
    }
}

module.exports = require('../inc-build').extend( feed, module );
