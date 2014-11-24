var mods = {
	df: 	require('dateformat'),
	path:	require('path'),
	tt:		require('semo/lib/tinytemper')
}
var utils = require('semo/eventpac/utils');
var eputils = require('../eputils');

exports.active = true;

exports.exts = {
    uriSchemes: eputils.schemes('templates')
}
exports.download = function( cx ) {}
var pages = [{
			'id': 1,
			'title' : 'Image banner',
			'image' : {
					'banner' : true,
					'shape': 'banner',
					'url' : 'images/friday.jpg'
			},
			'content' : {
				'dropCap': "",
				'html' : "<p>Lorem ipsum dolor sit amet,consectetur adipiscing elit. Vivamus molestie odio tortor, </p><p>id varius neque ultrices vitae. Duis pellentesque pellentesque arcu, ac placerat risus rhoncus eu. Etiam </p>"
			}

		},{
			'id': 2,
			'title' : 'Image circle',
			'image' : {
					'banner' : false,
					'shape' : 'circle',
					'url' : 'images/friday.jpg'
			},
			'content' : {
				'dropCap': "",
				'html' : '<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus molestie odio tortor, </p><p>id varius neque ultrices vitae. Duis pellentesque pellentesque arcu, ac placerat risus rhoncus eu. Etiam </p>'
			}

		}];
	var styles = [{
		'font': {
			'googleFont' : 'Roboto',
			'body' :{
				'size': '16px',
				'family': 'roboto',
				'style': 'normal',
				'weight': 400,
				'color': '#000',
				'lineHeight': 1.8

			},
			'title' :{
				'size': '1.8em',
				'family': 'roboto',
				'style': 'italic',
				'weight': 100,
				'color': '#fff',
				'lineHeight': 1.8
			}	
		},

		'color': {
			'highlight': '#E51C23',
		
			'body': {
				'text': '#000',
				'background': '#fff'

			},
			'title': {
				'text': '#fff',
				'background': '#4dbd9d',
			}

		}
	}];

exports.build = function( cx ){
	cx.file([
		'css',
		'fonts',
		'images',
		'js'
	]).cp();
    console.log(styles);
	cx.eval('template.html', pages, 'page-{id}.html');
	cx.eval('css/template.css', styles, 'styles.css');
}
exports.inPath = require('path').dirname(module.filename);
