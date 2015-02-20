//
//  EPGlobalsSchemeHandler.m
//  EPCore
//
//  Created by Julian Goacher on 28/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPGlobalsSchemeHandler.h"

@implementation EPGlobalsSchemeHandler

- (id)initWithGlobalModel:(EPJSONModel *)model {
    self = [super init];
    if (self) {
        globalModel = model;
    }
    return self;
}

- (IFResource *)handle:(IFCompoundURI *)uri parameters:(NSDictionary *)params parent:(IFResource *)parent {
    IFResource *result = nil;
    id value = [globalModel getValueForPath:uri.name];
    if (value) {
        result = [[IFResource alloc] initWithData:result uri:uri parent:parent];
        result.updateable = YES;
    }
    return result;
}

- (EPResourceModel *)getResourceModel:(EPController *)controller {
    return [[EPResourceModel alloc] init];
}

@end
