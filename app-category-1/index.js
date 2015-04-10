var settings = require('./general');
var imageSettings = require('./images-settings-test');
var exec = require('child_process').exec;
var path = require('path');
var less = require('less');
var fs = require('fs');

var category = settings.appCategory;
var name = settings.name;

function capitalize( string, capitalize ) { 
    if (capitalize){
        return string[0].toUpperCase() + string.slice(1); 
    }
    return string;
}
function generateLessVars( object, data ) {
    //called from getLessVars.
    //Check the properties in each section and subsections (such as title in header), and generate vars and structure from them

    //object: a section
    //data: 
    var sectionName = data.sectionName; //Name of the section we are checking (to include less structure)
    var sectionSet = data.sectionSet ; //Set of sections in case whe find more (to generate the vars)
    var typeName = data.typeName; //type we want to override it styles, if generalVars typename= '''

    var lessStructure='', overrideVars='',lessProperties='';

    var cssStylesProp = { 'backgroundColor':'background','HBackgroundColor':'background', 'fontSize':'font-size', 'fontStyle':'font-style', 'textAlign':'text-align', 'color':'color', 'fontFamily':'font-family'};

    lessStructure += '    >.'+sectionName;
    if (sectionName =='header') {
        lessStructure += ' , >'+ sectionName;
    } 

    lessStructure += ' {\n';
    for ( var prop in object){
        
        var existsProp = cssStylesProp[prop] != "undefined" ? true : false;

        //if is a property, generate the code.
        if ( (typeof object[prop] != 'object') && ( cssStylesProp[prop] != "undefined" ) ) {
        
            var property = object[prop];
            sectionSet = (typeName =='' ) ? capitalize(sectionSet, false) : capitalize(sectionSet, true);
            
            //add the var
            var varName = '@' +typeName+ sectionSet  +capitalize(prop, true) ;
            var newVar = varName + ' : '+ property+';  \n';
            //add the correct property with the var as a value
            lessProperties += '        '+cssStylesProp[prop]+' : '+varName +'; \n';//newvar
            overrideVars = overrideVars.concat(newVar);                   
        
        //if not, it's a subsection (such as title in header) and needs to be check to get its value
        } else {
    
            var data = {sectionName: prop, sectionSet: sectionSet+capitalize(prop, true), typeName: typeName};

            overrideStylesCss=generateLessVars(object[prop], data);

            overrideVars += overrideStylesCss.overrideVars;
            lessProperties += overrideStylesCss.lessStructure; 
        }
    }
    lessStructure += lessProperties + ' \n }';
    
    return {overrideVars: overrideVars, lessStructure:lessStructure};

}
function getLessVars( styleData ) {
    //generate all the vars and less structure necessary.

        var lessStructure='';
        var overrideVars='';

        //generate generalvars 
        var generalVars =  "@fontFamily : " + styleData.contentStyles.fontFamily +";\n";
        for ( var idx in styleData.contentStyles ) {
         
            if (['tabs', 'list', 'titleBar', 'fontFamily'].indexOf(idx) == -1 ){
   
                var section = styleData.contentStyles[idx];
                var data = {typeName: '', sectionName: idx, sectionSet: idx};

                if ( typeof section == 'object'){
                    //in general vars don't need the less structure
                    generalVars += generateLessVars( styleData.contentStyles[idx], data ).overrideVars;
                }
            }
        }

        //generate vars to override and less structure
        for ( var idx in styleData.types ){ 
            
            var typeName = styleData.types[idx].id;
            var styles = styleData.types[idx].styles;

            lessStructure += '.'+typeName+' {\n';

            for (var section in styles){
                if(section=='description' && styles[section]['backgroundColor']){
                    lessStructure += '\n background : ' +  '@'+typeName+'DescriptionBackgroundColor; \n';
                }
                var data = {typeName: typeName, sectionName: section, sectionSet: section};

                var overrideStylesCss =generateLessVars( styles[section], data );

                overrideVars = overrideVars.concat(overrideStylesCss.overrideVars);                
                lessStructure = lessStructure.concat(overrideStylesCss.lessStructure);                
            }

            //close class parent after read types.
            lessStructure += '} \n';
        }

        var lessVars =  overrideVars + generalVars ;

        return {lessVars : lessVars, lessStructure: lessStructure}; 
}

function gradientProperty( styles ) {
    for (var idx in styles) {
        var style = styles[idx];
        if ( typeof style.backgroundColor == "object" ) {
            var color1 = style.backgroundColor[0],
                color2 = style.backgroundColor[1] || color1;
            style.backgroundColor = 'linear-gradient(to right, '+ color1 +' , '+ color2 +')';
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

exports.build = function( cx ) {
    // Eval content CSS
    var styleData = settings;
    var postsArray = [];

    // TODO: Verification of inHeader within the main Style too
    styleData.styles = gradientProperty( styleData.styles );
    for (var idx in styleData.types) {
        var post = styleData.types[idx];
        var sData = styleData.styles ;
        if (post.styles) {
            if (idx == 'performers') {
                sData.image.HBackgroundColor = setHeadBgColor(sData, sData.image, post.styles);
            } else if (idx == 'events') {
                sData.time.HBackgroundColor = setHeadBgColor(sData, sData.time, post.styles);
            }
        }
        post.id = idx;
        postsArray.push(post);
    }
    styleData = { contentStyles: styleData.styles, types: postsArray};

    var cwd = path.resolve(process.cwd(), '..');
    var outputRoute= cwd+'/eventpac-feeds/app-category-1/feed/base/css/contentStyle.css';

    var lessTemplate = cwd +'/eventpac-feeds/app-category-1/template.less';
    var lessTemplateContent = fs.readFileSync(lessTemplate).toString();
    
    var overrideStylesCss = getLessVars(styleData);
    var lessVars = overrideStylesCss.lessVars;
    var overrideLessStyles = overrideStylesCss.lessStructure;

    var lessToRender =  lessVars + lessTemplateContent + overrideLessStyles;
    less.render( lessToRender,
        function (e, output) {
            console.log(e);
            fs.writeFile(outputRoute, output.css, function(err) {
                console.log(err);   
            });
        }
    );

    // Create styles.json
    cx.json(settings, name+'/app/common/styles.json', true);

    // Copy feed folder
    cx.file(['feed']).cp(name);
    
    // Generate app folder
    cwd += '/eventpac-feeds/scripts';
    var output = name+'/app';
    exec(cwd+'/makeclient.sh '+ name + ' '+ output, function(err, stdout, stderr) {
        //console.log('stdout: ' + stdout);
        //console.log('stderr: ' + stderr);
        if (err !== null) {
        //    console.log('exec error: ' + err);
        }
    });
    
    cx.file(['home.xml']).cp(name+'/app/and/res/layout/home.xml');

    // Create strings.json
    cx.json(settings.locale, name+'/app/common/strings.json', true);
    
    // Eval settings script
    cx.eval('feed/settings.js', settings, name+'/feed/settings.js');

    // Resize images App
    var appImages = settings.appImages;
    var imageInfo = imageSettings;
    for (var key in appImages) {
        var imageProperties = imageInfo[key];
        var image = cx.images( appImages[key] );
        for (var idx in imageProperties) {
            var newImage = imageProperties[idx];
            image.resize({width: newImage.width, height: newImage.height, format: 'png', mode: 'crop'}, name+'/app/'+newImage.filename+'.{format}' );
        }
    }
};
