var q = require('semo/lib/q');
var format = require('util').format;

// Functions for generating EP URIs, by scheme.
exports.schemes = function( feedid ) {
    var schemes = {
        'subs': function() {
            return this.href()
            .then(function( href ) {
                return format('subs:/%s/%s', feedid, href );
            });
        }
    };
    return schemes;
}

// Function for generating an action URI.
// @viewName:   An EP view name.
// @viewParams: An object mapping parameter names to values. Values may be deferred promises.
exports.action = function( viewName, viewParams ) {
    var params = Object.keys( viewParams )
    .map(function( name ) {
        return q.Q( viewParams[name] )
        .then(function( value ) {
            return [ name, value ];
        });
    });
    return q.all( params )
    .then(function( params ) {
        params = params.reduce(function( result, param ) {
            return result+'+'+param[0]+'@'+param[1];
        }, '');
        return format('nav/open+view@%s%s', viewName, params );
    });
}

exports.manifest = function( db ) {
    for( var table in db ) {
        db[table] = { updates: db[table] };
    }
    return { db: db };
}
