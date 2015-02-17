//
//  EPGoogleMapService.m
//  EPCore
//
//  Created by Julian Goacher on 06/01/2015.
//  Copyright (c) 2015 Julian Goacher. All rights reserved.
//

#import "EPGoogleMapService.h"
#import "IFCore.h"
#import <GoogleMaps/GoogleMaps.h>

static const int ddLogLevel = IFCoreLogLevel;

@implementation EPGoogleMapService

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        apiKey = [config getValueAsString:@"apiKey"];
    }
    return self;
}

- (void)startService {
    if (apiKey) {
        DDLogInfo(@"Starting Google Maps service with API key %@", apiKey);
        [GMSServices provideAPIKey:apiKey];
    }
}

- (void)stopService {
}


@end
