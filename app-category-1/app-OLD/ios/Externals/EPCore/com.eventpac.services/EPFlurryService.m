//
//  EPFlurryService.m
//  EventPacComponents
//
//  Created by Julian Goacher on 26/11/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "EPFlurryService.h"
#import "IFCore.h"
#import "Flurry.h"

static const int ddLogLevel = IFCoreLogLevel;

@implementation EPFlurryService

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        appKey = [config getValueAsString:@"appKey"];
    }
    return self;
}

- (void)startService {
    if (appKey) {
        DDLogInfo(@"Starting Flurry service with app key %@", appKey);
        [Flurry startSession:appKey];
    }
}

- (void)stopService {
}

@end
