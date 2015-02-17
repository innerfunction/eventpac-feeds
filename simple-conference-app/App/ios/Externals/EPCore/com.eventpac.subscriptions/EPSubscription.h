//
//  EPSubscription.h
//  EPCore
//
//  Created by Julian Goacher on 02/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPSubscriptionService.h"
#import "EPController.h"
#import "ZipArchive.h" // TODO: This probably can/should be moved to EPPeriodicSubscription

#define SubscriptionLocalStorageKeyPrefix @"eventpac.subscription"

typedef void (^NSURLConnectionHandler)(NSURLResponse*, NSData*, NSError*);

@interface EPSubscription : NSObject <EPSubscriptionFeed, NSURLConnectionDataDelegate, ZipArchiveDelegate> {
    EPConfiguration *configuration;
    EPController *mvc;
    NSString *lastModifiedHeader;
    NSDate *lastModifiedDate;
    NSString *downloadFilePath;
    NSFileHandle *downloadFileHandle;
    NSUserDefaults *localStorage;
    NSFileManager *fileManager;
    BOOL refresh;
}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *downloadFileExtension;
@property (nonatomic, strong) EPSubscriptionService *subscriptionService;
@property (nonatomic, strong) NSString *subscriptionURL;
@property (nonatomic, strong) NSString *lastModifiedLocalStorageKey;
@property (nonatomic, strong) NSString *lastRequestedLocalStorageKey;

- (BOOL)isPeriodic;
- (void)refresh;
- (BOOL)prepareForDownload;
- (NSDate *)parseHTTPDate:(NSString *)date defaultDate:(NSTimeInterval)defaultDate;

@end
