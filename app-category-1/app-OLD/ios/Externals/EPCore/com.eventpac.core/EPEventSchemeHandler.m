//
//  EPEventSchemeHandler.m
//  EPCore
//
//  Created by Julian Goacher on 23/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPEventSchemeHandler.h"
#import "EPCore.h"

@implementation EPEventSchemeHandler

- (id)initWithConfiguration:(EPConfiguration *)config {
    return [super init];
}

- (IFResource *)handle:(IFCompoundURI *)uri parameters:(NSDictionary *)params parent:(IFResource *)parent {
    EPEvent *event = [[EPEvent alloc] initWithData:nil uri:uri parent:parent];
    event.arguments = params;
    return event;
}

@end
