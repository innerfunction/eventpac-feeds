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
        // Generate content CSS
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
        //cx.eval('../'+category+'/template.css', styleData, 'contentStyle.css');
        
        //Generate APP config files
        cx.file('../'+category).cp(name+'/');
    }
};
