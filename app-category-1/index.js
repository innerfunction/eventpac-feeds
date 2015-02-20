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

module.exports = {
    build: function( cx ) {
        // Create styles.json
        cx.json(settings, name+'/app/common/styles.json', true);

        // Copy feed folder
        cx.file(['app', 'feed']).cp(name);
        
        // Eval settings script
        cx.eval('feed/settings.js', settings, name+'/feed/settings.js');
        
        // Eval content CSS
        var styleData = settings;
        var postsArray = [];
        for (var idx in styleData.types) {
            var post = styleData.types[idx];
            if (post.styles) {
                post.styles = gradientProperty(post.styles);
            }
            post.id = idx;
            postsArray.push(post);
        }
        styleData.styles = gradientProperty( styleData.styles );
        styleData = { contentStyles: styleData.styles, types: postsArray};
        cx.eval('feed/template.css', styleData, name+'/feed/base/css/contentStyle.css');
    }
};
