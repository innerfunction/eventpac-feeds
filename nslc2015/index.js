var mods = {
    ch:     require('cheerio'),
	df: 	require('dateformat'),
	path:	require('path'),
	tt:		require('semo/lib/tinytemper')
};
var format = require('util').format;
var utils = require('semo/eventpac/utils');
var eputils = require('../eputils');
var settings = require('./settings');
var ICalDateFormat = 'UTC:yyyymmdd\'T\'HHMMss\'Z\'';

function isPublished( post ) {
    return post.status == 'published';
}

function buildImages( cx, updates, opts ) {
    opts = opts||{};
    var imageURLs = updates.map(function map( post ) {
        return post.image;	
    })
    .filter(function( url ) {
        return !!url;
    });
    var images = cx.images( imageURLs );
    var size = opts.size||500;
    var format = opts.format||'jpeg';
    var mode = opts.mode||'crop';
    images.resize({ width: size, height: size, format: format, mode: mode }, true ).mapTo( updates, 'image' );
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

function linkButtonHTML( icon, url, title ) {
    var data = {
        icon:   icon,
        url:    url,
        title:  title
    };
    var html = '<button class="social {icon}"><a href="{url}"><i class="fa fa-{icon}"></i>&nbsp;{title}</a></button>';
    return mods.tt.eval( html, data );
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
                type:       'page',
                title:      post.title,
                status:     post.status,
                slug:       post.slug,
                content:    formatHTML( post.content )
            }
        },
        programme: function( post ) {
            var occurrence = post['event-date'][0];
            var timeMarker  = (settings.timeShape == 'circle' ) ? ' <br/> ' : '';
            return {
                id:             post.id,
                type:           'programme',
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
                speakers:       post.speakers
            }
        },
        speakers: function( post ) {
            var banner = (settings.imageShape == "banner") ? true : false;
            return {
                id:                 post.id,
                title:              post.title,
                shortDescription:   post.shortDescription,
                content:            formatHTML( post.content ),
                company:            post.company,
                companyUrl:         post.companyUrl,
                linkedin:           post.linkedin,
                twitter:            post.twitter,
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
                type:               'exhibitors',
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
                            var icon = r[1];
                            var url = href;
                            var title = r[2];
                            var html = linkButtonHTML( icon, url, title );
                            $a.replaceWith( $( html ) );
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
                    var speakers;
                    if( post.speakers ) {
                        speakers = post.speakers.map(function map( speaker ) {
                            return {
                                uri:    eputils.action('SpeakerDetail', { 'speakerID': speaker.ID }),
                                name:   speaker.post_title
                            }
                        });
                    }
                    return {
                        id:             post.id,
                        uid:            format('eventpac-%s-%s', feed.name, post.id ),
                        type:           post.type,
                        title:          post.title,
                        description:    post.description,
                        date:           post.date,
                        time:           post.time,
                        startTime:      post.startTime,
                        endTime:        post.endTime,
                        action:         eputils.action('EventDetail', { 'eventID': post.id }),
                        content:        post.content,
                        speakers:       speakers,
                        calendar: {
                            startTime:  mods.df( post.startTime, ICalDateFormat ),
                            endTime:    mods.df( post.endTime, ICalDateFormat ),
                            nowTime:    mods.df( new Date(), ICalDateFormat ),
                            location:   settings.name
                        }
                    }
                });
                cx.eval('icalendar.txt', updates, 'event-{id}.ics');
                cx.eval('event-template.html', updates, 'event-{id}.html');
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
        speakers: {
            depends: 'speakers',
            build: function( cx, updatesByType ) {
                var updates = updatesByType.speakers.map(function map( post ) {
                    var content = post.content;
                    if( post.linkedin ) {
                        content += linkButtonHTML('linkedin', post.linkedin, 'LinkedIn');
                    }
                    if( post.twitter ) {
                        content += linkButtonHTML('twitter', post.twitter, 'Twitter');
                    }
                    if( post.companyUrl ) {
                        content += linkButtonHTML('globe', post.companyUrl, 'Website');
                    }
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
                        content:            content,
                        shape:              post.shape,
                        banner:             post.banner
                    }
                });
                buildImages( cx, updates );
                cx.eval('template.html', updates, 'speaker-{id}.html');
                // List data
                return updates.map(function update( post ) {
                    return {
                        id:             post.id,
                        type:           post.type,
                        title:          post.title,
                        description:    post.company,
                        image:          post.image && post.image.uri('@subs'),
                        action:         post.action
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
                })
                .map(function map( exhib ) {
                    return {
                        id:         exhib.id,
                        title:      exhib.title,
                        image:      exhib.image
                    }
                });
                // List images.
                var srcs = exhibitors.map(function map( exhib ) {
                    return exhib.image;
                })
                .filter(function filter( url ) {
                    return !!url;
                });
                cx.images( srcs ).resize({ height: 70, width: 250, format: 'png', mode: 'fit' }, true ).mapTo( exhibitors, 'image' );
                // List data.
                var data = exhibitors.map(function map( exhib ) {
                    var imageURI = exhib.image && exhib.image.uri('@subs');
                    var title = imageURI ? '' : exhib.title;
                    return {
                        accessory:                  'DisclosureIndicator',
                        action:                     eputils.action('ExhibitorDetail', { 'exhibitorID': exhib.id }),
                        title:                      title,
                        backgroundImage:            imageURI,
                        selectedBackgroundImage:    imageURI,
                        height:                     100
                    }
                });
                // List JSON.
                cx.json( data, 'exhibitors.json' );

                // Updated exhibitors.
                exhibitors = updatesByType.exhibitors;
                exhibitors.forEach(function each( exhib ) {
                    if( exhib.url ) {
                        exhib.content += linkButtonHTML('globe', exhib.url, 'Website');
                    }
                });
                // Page images.
                buildImages( cx, exhibitors );
                // Build pages.
                cx.eval('template.html', exhibitors, 'exhibitor-{id}.html');
            }
        }
    }
}

module.exports = require('../inc-build').extend( feed, module );
