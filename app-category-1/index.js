var settings = require('./general');

var category = settings.appCategory;
var name = settings.name;

function gradientProperty( styles ) {
    for (var idx in styles) {
        var style = styles[idx];
        if ( typeof style.backgroundColor == "object") {
            var color1 = style.backgroundColor[0],
                color2 = style.backgroundColor[1] || color1;
            style.backgroundColor = 'linear-gradient(to right, '+ color1 +' , '+ color2 +');'
        }                 
    }
    return styles;
}

function  setHeadBgColor(styles, style, pStyle) {
    if (style.inHeader) {
        if (pStyle.header && pStyle.header.backgroundColor ) { 
            return pStyle.header.backgroundColor; 
        } else {
            return styles.header.backgroundColor;
        }
    } else if (!style.inHeader) {
         if ( pStyle.description && pStyle.description.backgroundColor ) {
            return pStyle.description.backgroundColor; 
        } else {
            return styles.description.backgroundColor;
        }
    }
}

module.exports = {
    build: function( cx ) {
        // Create styles.json
        cx.json(settings, name+'/app/common/styles.json', true);

        // Copy feed folder
        cx.file([ 'feed']).cp(name);
        
        // Eval settings script
        cx.eval('feed/settings.js', settings, name+'/feed/settings.js');
        
        // Eval content CSS
        var styleData = settings;
        var postsArray = [];
        styleData.styles = gradientProperty( styleData.styles );
        for (var idx in styleData.types) {
            var post = styleData.types[idx];
            var sData = styleData.styles ;
            if (post.styles) {
                post.styles = gradientProperty(post.styles);
            }
            if (idx == 'performers') {
                sData.image.HBackgroundColor = setHeadBgColor(sData, sData.image, post.styles);
            } else if (idx == 'events') {
                sData.time.HBackgroundColor = setHeadBgColor(sData, sData.time, post.styles);
            }
            post.id = idx;
            postsArray.push(post);
        }
        styleData = { contentStyles: styleData.styles, types: postsArray};
        cx.eval('feed/template.css', styleData, name+'/feed/base/css/contentStyle.css');

        // Resize images App
        /*var appImages = settings.appImages;
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
            
        }*/
    }
};
