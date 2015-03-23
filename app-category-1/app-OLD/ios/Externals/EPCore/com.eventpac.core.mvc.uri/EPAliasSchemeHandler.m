//
//  EPAliasSchemeHandler.m
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPAliasSchemeHandler.h"
#import "EPAliasResourceModel.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

@implementation EPAliasSchemeHandler

- (id)initWithResolver:(id<IFURIResolver>)_resolver aliases:(NSDictionary *)_aliases {
    self = [super init];
    if (self) {
        resolver = _resolver;
        aliases = [[EPJSONModel alloc] initWithData:_aliases];
    }
    return self;
}

- (IFCompoundURI *)resolveAliasToURI:(NSString *)alias {
    NSString *suri = [[aliases getValueForPath:alias] description];
    NSError *error = nil;
    IFCompoundURI *uri = [[IFCompoundURI alloc] initWithURI:suri error:&error];
    if (error) {
        DDLogError(@"EPAliasSchemeHandler: Alias %@ does not resolve to a valid URI (%@)", alias, suri);
    }
    return uri;
}

- (IFResource *)handle:(IFCompoundURI *)uri parameters:(NSDictionary *)params parent:(IFResource *)parent {
    IFResource *result = nil;
    IFCompoundURI *auri = [self resolveAliasToURI:uri.name];
    if (auri) {
        result = [resolver resolveURI:auri context:parent];
        result.updateable = YES;
    }
    return result;
}

- (EPResourceModel *)getResourceModel:(EPController *)controller {
    return [[EPAliasResourceModel alloc] initWithController:controller handler:self];
}

@end
