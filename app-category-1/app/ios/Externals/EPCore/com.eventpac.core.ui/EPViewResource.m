//
//  EPViewResource.m
//  EPCore
//
//  Created by Julian Goacher on 03/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPViewResource.h"
#import "EPViewFactoryService.h"

@implementation EPViewResource

- (id)initWithConfiguration:(EPConfiguration *)config factory:(EPViewFactoryService *)_factory uri:(IFCompoundURI *)uri parent:(IFResource *)parent {
    self = [super initWithData:config.data uri:uri parent:parent];
    if (self) {
        configuration = config;
        factory = _factory;
    }
    return self;
}

- (UIViewController *)asView {
    return [factory makeViewForURI:self.uri configuration:configuration];
}

- (id)asDefault {
    return [self asView];
}

- (id)asRepresentation:(NSString *)representation {
    if ([@"view" isEqualToString:representation]) {
        return [self asView];
    }
    if ([@"json" isEqualToString:representation]) {
        return configuration.data;
    }
    return [super asRepresentation:representation];
}

@end
