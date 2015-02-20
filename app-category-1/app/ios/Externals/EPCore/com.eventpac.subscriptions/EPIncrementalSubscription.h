//
//  EPIncrementalFeed.h
//  EPCore
//
//  Created by Julian Goacher on 03/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPSubscriptionService.h"
#import "ZipArchive.h"

#define LocalStorageKey(name)       ([NSString stringWithFormat:@"feed.%@.%@", feedID, name])
#define GetLocalValue(name)         ([localStorage stringForKey:LocalStorageKey(name)])
#define SetLocalValue(name,value)   ([localStorage setValue:value forKey:LocalStorageKey(name)])
#define RemoveLocalValue(name)      ([localStorage removeObjectForKey:LocalStorageKey(name)])

@interface EPIncrementalSubscription : NSObject <EPSubscriptionFeed, ZipArchiveDelegate> {
    EPConfiguration *configuration;
    NSFileManager *fileManager;
    NSUserDefaults *localStorage;
    NSString *feedID;
    NSString *feedURL;
    BOOL periodic;
    NSString *contentURL;
    NSString *contentDirPath;
    NSString *downloadFilename;
}

- (void)startDownload;
- (void)resumeDownload;
- (void)checkForUpdates;
- (void)downloadContent:(NSString *)url;
- (void)contentDownloadCompleted:(BOOL)ok;
- (void)unpackContentFromFile:(NSString *)contentZipPath;
- (void)finishDownload;

@end
