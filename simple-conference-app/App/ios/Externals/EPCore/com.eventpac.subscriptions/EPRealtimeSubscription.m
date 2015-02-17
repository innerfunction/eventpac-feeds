//
//  EPRealtimeSubscription.m
//  EPCore
//
//  Created by Julian Goacher on 02/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPRealtimeSubscription.h"
#import "EPDBManifestProcessor.h"
#import "JSONKit.h"

@implementation EPRealtimeSubscription

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super initWithConfiguration:config];
    if (self) {
        self.downloadFileExtension = @"json";
    }
    return self;
}

- (BOOL)isPeriodic {
    return NO;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // TODO: Read char encoding from http response
    NSString *json = [[NSString alloc] initWithContentsOfFile:downloadFilePath encoding:NSUTF8StringEncoding error:nil];
    id data = [json objectFromJSONString];

    IFResource *rsc = [self.subscriptionService getResourceForPath:downloadFilePath];

    EPConfiguration *config = [[EPConfiguration alloc] initWithData:data resource:rsc];
    if ([config getValueType:@"db"] == EPValueTypeObject) {
        config = [config getValueAsConfiguration:@"db"];
    }
    EPDBManifestProcessor *manifestProcessor = [[EPDBManifestProcessor alloc] initWithConfiguration:config];
    [manifestProcessor process];

    [super connectionDidFinishLoading:connection];
}

@end
