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
    //Check the properties in each section and subsections (such as title is inside header), and generate vars and structure from them

                                            //object: a section to read.
                                            //data: 
    var typeName = data.typeName;                //page type we want to override it styles, if generalVars typename= '' '                                        
    var sectionName = data.sectionName;          //Name of the section we are checking (to include less structure)
    var sectionSet = data.sectionSet ;           //Set of parent sections in case whe find more than one (to generate the name vars)

    var lessStructure='', overrideVars='',lessProperties='';

    var cssStylesProp = { 'backgroundColor':'background','HBackgroundColor':'background', 'fontSize':'font-size', 'fontStyle':'font-style', 'textAlign':'text-align', 'color':'color', 'fontFamily':'font-family'};

    lessStructure += '    > .'+sectionName;
    if (sectionName =='header') {  // if the section is the header, we need to apply styles for class header and html element header
        lessStructure += ' , >'+ sectionName;
    } 

    lessStructure += ' {\n';
    for ( var prop in object){
        
        var existsProp = cssStylesProp[prop] != "undefined" ? true : false;

        //if is a property, generate the code.
        if ( (typeof object[prop] != 'object') && ( cssStylesProp[prop] != "undefined" ) ) {
        
            var propertyValue = object[prop];
            sectionSet = (typeName =='' ) ? capitalize(sectionSet, false) : capitalize(sectionSet, true);
            
            //add the var
            var varName = '@' +typeName+ sectionSet  +capitalize(prop, true) ; //less var name. 

            //less var definition with its content 
            var newVar = varName + ' : '+ propertyValue+';  \n';  // result:    @speakerHeaderTitleHBackgroundColor: #fff

            //add the correct property to the less structure with the var as a value
            lessProperties += '        '+cssStylesProp[prop]+' : '+varName +'; \n'; // result:    background-color: @speakerHeaderTitleHBackgroundColor

            overrideVars = overrideVars.concat(newVar);     //add new var to the list.              
        
        //if not, it's a subsection (such as title in header) and needs to be check to get its properties
        } else {
            // data to generate the vars
                //section name: is the name of the section to loop (title).
                //sectionset:   section we were reading ( eg.:Header)  + section we're about to loop (eg.: title )

            var data = {sectionName: prop, sectionSet: sectionSet+capitalize(prop, true), typeName: typeName};

            overrideStylesCss=generateLessVars(object[prop], data);

            overrideVars += overrideStylesCss.overrideVars; //save generated vars
            lessProperties += overrideStylesCss.lessStructure;  //save generated less structure
        }
    }
    lessStructure += lessProperties + ' \n }'; //close less block for the section.
    
    return {overrideVars: overrideVars, lessStructure:lessStructure};

}
function getLessVars( styleData ) {
    //generate all the vars and less structure necessary.
    // styleData.contentStyles  : general styles for the app
    // styleData.types          : styles to override styles in specific pages

        var lessStructure='';
        var overrideVars='';

        //generate generalvars 
        var generalVars =  "@fontFamily : " + styleData.contentStyles.fontFamily +";\n";
        for ( var idx in styleData.contentStyles ) {
         
            //if the section is not any of this ones
            if (['tabs', 'list', 'titleBar', 'fontFamily'].indexOf(idx) == -1 ){

                var section = styleData.contentStyles[idx];
                var data = {typeName: '', sectionName: idx, sectionSet: idx};

                if ( typeof section == 'object'){
                    //if section is an object, we loop on its properties to get the less vars.

                    generalVars += generateLessVars( styleData.contentStyles[idx], data ).overrideVars;
                    //in general vars we don't need the less structure, so we just take the vars from the result

                }
            }
        }

        //generate vars to override styles in pages and it less structure
        for ( var idx in styleData.types ){ 
            
            var typeName = styleData.types[idx].id; // .title instead of .id if errors ?
            var styles = styleData.types[idx].styles;

            lessStructure += '.'+typeName+' {\n'; //start to generate less structure to override, by taking as parent the pageType to override and setting inside it sections

            for (var section in styles){
                if(section=='description' && styles[section]['backgroundColor']){
                    lessStructure += '\n background : ' +  '@'+typeName+'DescriptionBackgroundColor; \n';
                }

                var data = {typeName: typeName, sectionName: section, sectionSet: section};

                //Read the overriden properties for the secion  and generate the correct vars and less structure.
                var overrideStylesCss =generateLessVars( styles[section], data );

                overrideVars = overrideVars.concat(overrideStylesCss.overrideVars);                
                lessStructure = lessStructure.concat(overrideStylesCss.lessStructure);                
            }

            //close class parent after read all sections in the types.
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

    //get less to render:

    //route to save the css result
    var outputRoute= cwd+'/eventpac-feeds/app-category-1/feed/base/css/contentStyle.css';

    //get less template content
    var lessTemplate = cwd +'/eventpac-feeds/app-category-1/template.less';
    var lessTemplateContent = fs.readFileSync(lessTemplate).toString();
    
    //get dynamic less styles 
    var overrideStylesCss = getLessVars(styleData);

    //get less vars for the styles given.
    var lessVars = overrideStylesCss.lessVars;
    //get less structure for overriding pageTypes styles if given.
    var overrideLessStyles = overrideStylesCss.lessStructure;

    //concat all less parts in the correct order to be rendered
    var lessToRender =  lessVars + lessTemplateContent + overrideLessStyles;
    less.render( lessToRender,
        function (e, output) {
            console.log(e);
            //save the css result in the correct route.
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
