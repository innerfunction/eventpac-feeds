var format = require('util').format;

exports.schemes = function( feedid ) {
    return {
        'subs': function() {
            return this.href()
            .then(function( href ) {
                return format('subs:/%s/%s', feedid, href );
            });
        }
    }
}

exports.action = function( viewName, pname, pvalue ) {
    return 'nav/open+view@%s+%s@%s', viewName, pname, value );
}
