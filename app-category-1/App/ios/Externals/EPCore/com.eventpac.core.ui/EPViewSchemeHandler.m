//
//  EPViewSchemeHandler.m
//  EPCore
//
//  Created by Julian Goacher on 03/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPViewSchemeHandler.h"
#import "EPViewResource.h"
#import "EPCore.h"

@implementation EPViewSchemeHandler

@synthesize core;

- (id)initWithConfiguration:(EPConfiguration *)config {
    return [super init];
}

- (void)setCore:(EPCore *)_core {
    core =_core;
    viewFactory = [core getViewFactory];
}

- (IFResource *)handle:(IFCompoundURI *)uri parameters:(NSDictionary *)params parent:(IFResource *)parent {
    return [viewFactory makeViewResourceForURI:uri parameters:params parent:parent];
}

@end
