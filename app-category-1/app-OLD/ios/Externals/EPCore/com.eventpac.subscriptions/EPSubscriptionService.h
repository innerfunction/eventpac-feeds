//
//  SubscriptionService.h
//  EPCore
//
//  Created by Julian Goacher on 02/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPService.h"
#import "EPEventHandler.h"
#import "IFCompoundURI.h"
#import "IFResource.h"
#import "ISO8601DateFormatter.h"

@class EPSubscriptionService;

@protocol EPSubscriptionFeed <EPService>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) EPSubscriptionService *subscriptionService;

- (BOOL)isPeriodic;
- (void)refresh;

@end

@interface EPSubscriptionService : NSObject <EPService, EPEventHandler> {
    EPConfiguration* configuration;
    NSDictionary *subscriptions;
    double updateInterval;
    NSTimer* updateTimer;
    NSString *cachePath;
    NSString *epCachePath;
    ISO8601DateFormatter *dateFormatter;
    NSMutableArray *updatingSubscriptions;
}

@property (nonatomic, strong) NSString *downloadPath;
@property (nonatomic, strong) NSString *contentPath;
@property (nonatomic, strong) NSString *initialContentPath;
@property (nonatomic, strong) NSFileManager *fileManager;

- (IFCompoundURI *)getCacheURIForPath:(NSString *)path;
- (IFCompoundURI *)getSubsURIForPath:(NSString *)path;
- (IFResource *)getResourceForPath:(NSString *)path;
- (void)refreshPeriodicSubscriptions;
- (void)refreshSubscriptionWithName:(NSString *)name;
- (void)subscription:(id<EPSubscriptionFeed>)sub updating:(BOOL)updating;
- (NSString *)contentDirectoryPathForSubscription:(id<EPSubscriptionFeed>)sub;
// Ensure that the directory at the named path exists. Creates the directory if necessary.
- (BOOL)ensureDirectoryAtPath:(NSString *)path;
- (NSString *)currentTimeAs8601String;

@end
