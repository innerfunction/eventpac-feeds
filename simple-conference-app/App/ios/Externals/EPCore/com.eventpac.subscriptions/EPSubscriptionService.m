//
//  SubscriptionService.m
//  EPCore
//
//  Created by Julian Goacher on 02/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPSubscriptionService.h"
#import "EPCore.h"
#import "IFTimer.h"
#import "IFCore.h"
#import "NSString+IF.h"
#include <sys/xattr.h>

static const int ddLogLevel = IFCoreLogLevel;

#define DefaultSubscriptionUpdateInterval ([NSNumber numberWithInteger:3600])

// Notes on non-caching of content directories (taken from previous EP version):
// NOTE: This class downloads and stores data on the device's local filesystem. On iOS there are issues related to
// caching and backup of data that need to be understood. See the following posts for discussions of these issues:
// * http://www.marco.org/2011/10/13/ios5-caches-cleaning
// * http://iphoneincubator.com/blog/data-management/local-file-storage-in-ios-5
// This class attempts to stay withing the guidelines, and so does the following with downloaded content:
// * Initial content is stored in a zip file bundled with the app.
// * All content (initial and downloaded) is unpacked to a location under the /Caches directory. This location is
//   a directory named after the subscription and marked with a 'do not backup' attribute.
// * Any downloaded content is initialy written to the /tmp directory as a zip file. This file is deleted once its
//   content has been unpacked to the content directory.
// There may still be a problem if iOS deletes the contents of the /Caches directory because of low storage capacity.
// Potentially in that case, the app's content could disappear mid-use. Strategies for handling such as situation will
// need to be examined.
// Also see here: http://developer.apple.com/library/ios/#documentation/FileManagement/Conceptual/FileSystemProgrammingGUide/FileSystemOverview/FileSystemOverview.html
//   Handle support files—files your application downloads or generates and can recreate as needed—in one of two ways:
//   In iOS 5.0 and earlier, put support files in the <Application_Home>/Library/Caches directory to prevent them from being backed up
//   In iOS 5.0.1 and later, put support files in the <Application_Home>/Library/Application Support directory and apply the com.apple.MobileBackup extended
//   attribute to them. This attribute prevents the files from being backed up to iTunes or iCloud. If you have a large number of support files, you may store them
//   in a custom subdirectory and apply the extended attribute to just the directory.
//   Put data cache files in the <Application_Home>/Library/Caches directory. Examples of files you should put in this directory include (but are not limited to)
//   database cache files and downloadable content, such as that used by magazine, newspaper, and map apps. Your app should be able to gracefully handle situations
//   where cached data is deleted by the system to free up disk space.
// Also https://developer.apple.com/library/ios/#documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/PerformanceTuning/PerformanceTuning.html#//apple_ref/doc/uid/TP40007072-CH8-SW8

@implementation EPSubscriptionService

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        configuration = config;
        
        self.fileManager = [NSFileManager defaultManager];
        
        // Setup the content directory path.
        // Note: There is a cross dependency here with the cache: file based URI scheme handler. If more logic is needed to identify
        // the caches dir (see comments at top) then it will need to be shared with the uri handler.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        cachePath = [paths objectAtIndex:0];
        epCachePath = [cachePath stringByAppendingPathComponent:@"eventpac"];
        
        self.downloadPath = [epCachePath stringByAppendingPathComponent:@"zips"];
        if (![self ensureDirectoryAtPath:self.downloadPath]) {
            DDLogError(@"EPSubscriptionService: Unable to create download directory at %@", self.downloadPath);
        }
        
        self.contentPath = [epCachePath stringByAppendingPathComponent:@"subs"];
        if (![self ensureDirectoryAtPath:self.contentPath]) {
            DDLogError(@"EPSubscriptionService: Unable to create content directory at %@", self.contentPath);
        }
        
        self.initialContentPath = [MainBundlePath stringByAppendingPathComponent:[configuration getValueAsString:@"initialContentPath" defaultValue:@""]];
        
        if ([configuration getValueAsBoolean:@"resetContentAtStart" defaultValue:NO]) {
            DDLogInfo(@"EPSubscriptionService: Clearing content directory...");
            if ([self.fileManager removeItemAtPath:self.contentPath error:nil]) {
                DDLogInfo(@"EPSubscriptionService: Content directory cleared");
            }
            else {
                DDLogWarn(@"EPSubscriptionService: Failed to clear content directory");
            }
        }
        dateFormatter = [[ISO8601DateFormatter alloc] init];
        dateFormatter.includeTime = YES;
    }
    return self;
}

- (void)startService {
    DDLogInfo(@"EPSubscriptionService: Starting subscriptions...");
    
    EPCore *core = [EPCore getCore];
    NSMutableDictionary *_subscriptions = [[NSMutableDictionary alloc] init];
    
    // Setup all subscriptions described in the configuration.
    EPConfiguration *subConfigs = [configuration getValueAsConfiguration:@"subscriptions"];
    for (NSString *name in [subConfigs getValueNames]) {
        @try {
            EPConfiguration *subConfig = [subConfigs getValueAsConfiguration:name];
            NSString *cid = [NSString stringWithFormat:@"subscription: %@", name ];
            id<EPSubscriptionFeed> subscription = (id<EPSubscriptionFeed>)[core makeComponentWithConfiguration:subConfig identifier:cid];
            if (!subscription) {
                DDLogWarn(@"EPSubscriptionService: Failed to make subscription %@", name );
            }
            else {
                subscription.name = name;
                subscription.subscriptionService = self;
                [_subscriptions setObject:subscription forKey:name];
                DDLogInfo(@"EPSubscriptionService: Added subscription %@", [subscription description] );
                [subscription startService];
            }
        }
        @catch (NSException *exception) {
            DDLogError(@"EPSubscriptionService: Failed to start subscription %@", name );
            DDLogError(@"%@", exception);
        }
    }
    subscriptions = _subscriptions;
    
    if ([configuration getValueAsBoolean:@"refreshPeriodicSubscriptions" defaultValue:YES]) {
        updateInterval = [[configuration getValueAsNumber:@"updateInterval" defaultValue:DefaultSubscriptionUpdateInterval] doubleValue];
        DDLogInfo(@"EPSubscriptionService: Subscription update interval: %ld secs (%ld mins)", (long)updateInterval, (long)(updateInterval / 60));
        
        updateTimer = [IFTimerManager setRepeat:updateInterval action:^{
            [self refreshPeriodicSubscriptions];
        }];
        
        // Refresh subscriptions 30 secs after start.
        /*
        [IFTimerManager setDelay:30 action:^{
            [self refreshPeriodicSubscriptions];
        }];
        */
        [self refreshPeriodicSubscriptions];
    }
    else {
        DDLogWarn(@"EPSubscriptionService: Periodic subscription refresh disabled");
    }
    //[self refreshPeriodicSubscriptions];
}

- (void)stopService {
    DDLogInfo(@"EPSubscriptionService: Stopping periodic subscriptions...");
    [updateTimer invalidate];
}

- (void)refreshPeriodicSubscriptions {
    DDLogInfo(@"EPSubscriptionService: Refreshing periodic subscriptions...");
    // TODO: Should be checking for app connectivity here; e.g. only attempt downloads if the
    // app's connectivity matches some predefined condition, e.g. only on wifi, or on 3g but not roaming etc.
    for (id<EPSubscriptionFeed> sub in [subscriptions objectEnumerator]) {
        if ([sub isPeriodic]) {
            [sub refresh];
        }
    }
}

- (void)refreshSubscriptionWithName:(NSString *)name {
    id<EPSubscriptionFeed> sub = [subscriptions objectForKey:name];
    if (sub) {
        DDLogInfo(@"EPSubscriptionService: Refreshing subscription %@", name );
        [sub refresh];
    }
}

- (void)subscription:(id<EPSubscriptionFeed>)sub updating:(BOOL)updating {
    // Find the index of the subs object in the list of updating subs (-1 => not in array).
    NSInteger idx = -1;
    for (NSInteger i = 0; i < [updatingSubscriptions count]; i++) {
        // Looking for an instance match, so == is valid here.
        if ([updatingSubscriptions objectAtIndex:i] == sub) {
            idx = i;
            break;
        }
    }
    // Modify the list of updating subs.
    if (updating && idx == -1) {
        // If sub is updating and is not already on updating list then add to list.
        [updatingSubscriptions addObject:sub];
    }
    else if (!updating && idx != -1) {
        // If sub is not updating then remove from list.
        [updatingSubscriptions removeObjectAtIndex:idx];
    }
    // Notify app of update status.
    NSString *action = [updatingSubscriptions count] > 0 ? @"notify/updating" : @"notify/not-updating";
    [[EPCore getCore] dispatchAction:action];
}

- (id)handleEPEvent:(EPEvent *)event {
    id result = [EPEvent notHandledResult];
    if ([@"refresh" isEqualToString:event.action]) {
        NSString *subName = [(IFResource *)[event.arguments objectForKey:@"name"] asString];
        if (subName) {
            // Single sub name specified.
            [self refreshSubscriptionWithName:subName];
        }
        else {
            NSString *subNames = [(IFResource *)[event.arguments objectForKey:@"names"] asString];
            if (subNames) {
                // A comma separated list of sub names specified.
                for (NSString *name in [subNames split:@","]) {
                    [self refreshSubscriptionWithName:name];
                }
            }
            else {
                [self refreshPeriodicSubscriptions];
            }
        }
        result = nil;
    }
    return result;
}

- (IFCompoundURI *)getCacheURIForPath:(NSString *)path {
    IFCompoundURI *uri = nil;
    // NOTE: 'path' here should start with the cache dir path.
    if ([path hasPrefix:cachePath]) {
        NSUInteger idx = [cachePath length];
        uri = [[IFCompoundURI alloc] initWithScheme:@"cache" name:[path substringFromIndex:idx]];
        DDLogInfo(@"EPSubscriptionService: Resolving %@ for file %@", uri, path );
    }
    return uri;
}

- (IFCompoundURI *)getSubsURIForPath:(NSString *)path {
    IFCompoundURI *uri = nil;
    if ([path hasPrefix:self.contentPath]) {
        NSUInteger idx = [self.contentPath length];
        uri = [[IFCompoundURI alloc] initWithScheme:@"subs" name:[path substringFromIndex:idx]];
        DDLogInfo(@"EPSubscriptionService: Resolving %@ for file %@", uri, path );
    }
    return uri;
}

- (IFResource *)getResourceForPath:(NSString *)path {
    IFCompoundURI *uri = [self getSubsURIForPath:path];
    if (!uri) {
        uri = [self getCacheURIForPath:path];
    }
    return uri ? [[EPCore getCore].resolver resolveURI:uri] : nil;
}

- (NSString *)contentDirectoryPathForSubscription:(id<EPSubscriptionFeed>)sub {
    return [self.contentPath stringByAppendingPathComponent:sub.name];
}

- (BOOL)ensureDirectoryAtPath:(NSString *)path {
    BOOL ok = NO;
    if (!path) {
        DDLogError(@"EPSubscriptionService: ensureDirectoryAtPath - Path not specified");
    }
    else if (![self.fileManager fileExistsAtPath:path]) {
        DDLogInfo(@"EPSubscriptionService: Directory at %@ not found, creating...", path);
        NSError *error = nil;
        [self.fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error) {
            DDLogError(@"EPSubscriptionService: Unable to create directory at %@: %@", path, error );
        }
        else {
            // Mark the directory as not for backup.
            // See https://developer.apple.com/library/ios/#qa/qa1719/_index.html
            if (IsIOSVersionSince(@"5.1")) {
                NSURL* dirURL = [NSURL fileURLWithPath:path];
                if (![dirURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error]) {
                    DDLogError(@"EPSubscriptionService: Error excluding %@ from backup (5.1+): %@", path, error );
                }
                else {
                    ok = YES;
                }
            }
            else {
                u_int8_t attr = 1;
                int res = setxattr([path fileSystemRepresentation], "com.apple.MobileBackup", &attr, sizeof(attr), 0, 0);
                if (res != 0) {
                    DDLogError(@"EPSubscriptionService: Failed to set com.apple.MobileBackup attr on %@ (5.0.1-)", path);
                }
                else {
                    ok = YES;
                }
            }
        }
    }
    else {
        ok = YES;
    }
    return ok;
}

- (NSString *)currentTimeAs8601String {
    return [dateFormatter stringFromDate:[NSDate date] timeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
}

@end
