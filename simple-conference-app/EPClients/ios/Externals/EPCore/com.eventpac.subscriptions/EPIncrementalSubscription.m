//
//  EPIncrementalSubscription.m
//  EPCore
//
//  Created by Julian Goacher on 03/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPIncrementalSubscription.h"
#import "EPDBManifestProcessor.h"
#import "EPCore.h"
#import "Reachability.h"
#import "IFFileResource.h"
#import "IFStringTemplate.h"
#import "IFFileIO.h"
#import "IFCore.h"
#import "IFHTTPUtils.h"

static const int ddLogLevel = IFCoreLogLevel;
#define LogTag @"[EPIncrementalSubscription]"

// NOTES:
// 1. This sub unpacks content to the same file structure as the other sub types.
// 2. Sub-content wishing to access content in other subs must use ../<sub name> as the only reliable mechanism that will
//    work on both iOS and Android (assuming that the subs: scheme isn't available, e.g. from within a web page).
//    > Alternatively, is there any kind of aliasing scheme that could work cross-platform?
//    > A longer term solution may be to use a local http server.
// x. This sub should allow both periodic & non-periodic modes. The default mode is non-periodic; in this mode, downloads
//    are triggered either by a push notification or by user request, and in both cases, the sub is requested via an event.
// 4. Manifest processing has to be extended to support file deletion. It would have been useful to also support symlink
//    creation (as a solution to point 2 above), but this doesn't seem to be an option on android.
//    When processing the manifest, must also read and store the build number (TODO is noted below for this); and also
//    store the build or download date, for possible later presentation within the UI (date of last download/last checked
//    for download on date).
// x. Settings need to be added for controlling downloads (e.g. only download over wifi / never download), and these
//    settings need to be checked before starting a download.
@implementation EPIncrementalSubscription

@synthesize name, subscriptionService;

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        configuration = config;
        fileManager = [NSFileManager defaultManager];
        localStorage = [NSUserDefaults standardUserDefaults];

        feedID = [configuration getValueAsString:@"id"];
        self.name = feedID;
        
        feedURL = [configuration getValueAsString:@"url"];
        
        periodic = [configuration getValueAsBoolean:@"periodic" defaultValue:NO];
    }
    return self;
}

- (void)startService {
    fileManager = self.subscriptionService.fileManager;
    
    BOOL contentDirExists = NO, contentZipExists = NO, contentManifestExists = NO;
    
    contentDirPath = [self.subscriptionService contentDirectoryPathForSubscription:self];
    contentDirExists = [self.subscriptionService ensureDirectoryAtPath:contentDirPath];
    
    NSString *manifestFilePath = [contentDirPath stringByAppendingPathComponent:@"manifest.json"];
    contentManifestExists = [fileManager fileExistsAtPath:manifestFilePath];
    
    if (contentDirExists && !contentManifestExists) {
        IFResource *zipResource = [configuration getValueAsResource:@"zip"];
        if (!zipResource) {
            DDLogWarn(@"%@ Zip property for subscription %@ not found", LogTag, self.name);
        }
        else if (![zipResource isKindOfClass:[IFFileResource class]]) {
            DDLogWarn(@"%@ Zip property for subscription %@ must resolve to a file resource", LogTag, self.name);
        }
        else {
            IFFileResource *zipFileResource = (IFFileResource *)zipResource;
            NSString *zipFilePath = zipFileResource.fileDescription.path;
            contentZipExists = [fileManager fileExistsAtPath:zipFilePath];
            if (contentZipExists) {
                DDLogInfo(@"%@ Unpacking content for %@ from %@...", LogTag, self.name, zipFilePath);
                [self unpackContentFromFile:zipFilePath];
            }
        }
    }
}

- (void)stopService {}

- (BOOL)isPeriodic {
    return periodic;
}

- (void)refresh {
    NSString *downloadPolicy = [localStorage stringForKey:@"subscriptions.downloadPolicy"];
    DDLogInfo(@"%@ downloadPolicy=%@", LogTag, downloadPolicy);
    if ([@"never" isEqualToString:downloadPolicy]) {
        // Downloads disabled.
        return;
    }
    // Check connection status.
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    [reachability stopNotifier];
    switch (networkStatus) {
        case NotReachable:
            // No network, so can't download.
            DDLogCVerbose(@"%@ Network not reachable", LogTag);
            break;
        case ReachableViaWiFi:
            // Always download over wifi.
            DDLogCVerbose(@"%@ WIFI network available", LogTag);
            [self startDownload];
            break;
        case ReachableViaWWAN: // i.e. 3G
            DDLogCVerbose(@"%@ Mobile network available", LogTag);
            if (![@"wifi-only" isEqualToString:downloadPolicy]) {
                // Only download if policy isn't set to wifi only.
                [self startDownload];
            }
        default:
            DDLogCVerbose(@"%@ Unrecognized network status: %d", LogTag, networkStatus);
            break;
    }
}

- (void)startDownload {
    NSString *url = GetLocalValue(@"url");
    downloadFilename = GetLocalValue(@"filename");
    if (url && downloadFilename) {
        contentURL = url;
        [self resumeDownload];
    }
    else {
        [self checkForUpdates];
    }
}

- (void)resumeDownload {
    // Get download file size.
    NSDictionary *attr = [fileManager attributesOfItemAtPath:downloadFilename error:nil];
    NSNumber *fileSize = [attr valueForKey:NSFileSize];
    if (fileSize) {
        // Download file size found.
        // Download the file, starting from the offset of the amount previously downloaded.
        NSUInteger offset = [fileSize integerValue];
        __block IFHTTPClient *client = [IFHTTPUtils getFileFromURL:contentURL offset:offset path:downloadFilename then:^(BOOL ok) {
            client = nil;
            [self contentDownloadCompleted:ok];
        }];
    }
    else {
        // Download file not found; clean up the build and start again.
        [self finishDownload];
        [self checkForUpdates];
    }
}

- (void)checkForUpdates {
    NSString *since = GetLocalValue(@"buildid");
    if (!since) {
        since = @"";
    }
    // Feed URL can be specified as a template accepting the feed ID and since build as values.
    NSString *url = [IFStringTemplate render:feedURL context:@{ @"feed": feedID, @"since": since }];
    // TODO: Check ARC mem management here - does a ref to the client need to be kept until the download
    // is complete? Can HTTPUtils manage these references?
    __block IFHTTPClient *client = [IFHTTPUtils getJSONFromURL:url then:^(id data) {
        client = nil;
        NSString *status = @"unknown";
        @try {
            if (data) {
                status = [data valueForKey:@"status"];
            }
            if ([@"error" isEqualToString:status]) {
                // Log error
                DDLogError(@"%@ Error checking for updates: %@", LogTag, [data valueForKey:@"message"]);
                [self finishDownload];
            }
            else if ([@"no-update" isEqualToString:status] || [@"no-content-available" isEqualToString:status]) {
                // No update available
                DDLogCVerbose(@"%@ No update available", LogTag);
                [self finishDownload];
            }
            else if ([@"update-since" isEqualToString:status] || [@"current-content" isEqualToString:status]) {
                // Read content URL and start update download.
                DDLogCVerbose(@"%@ Update available", LogTag);
                NSString *url = [data valueForKey:@"url"];
                SetLocalValue(@"status", status);
                [self downloadContent:url];
            }
            else {
                [self finishDownload];
            }
        }
        @catch (NSException *exception) {
            // This will happen if data isn't key-value coding compliant.
            // No need to do anything specific with the exception.
            NSLog(@"%@ checkForUpdates: data isn't key-value coding compliant", LogTag);
            [self finishDownload];
        }
    }];
}

- (void)downloadContent:(NSString *)url {
    contentURL = url;
    SetLocalValue(@"url", url);
    // Delete any previous download file.
    if (downloadFilename) {
        [fileManager removeItemAtPath:downloadFilename error:nil];
    }
    // Setup the download file path. This is placed in the app's tmp directory.
    NSString *filename = [NSString stringWithFormat:@"com.eventpac.feed.%@.zip", self.name];
    downloadFilename = [self.subscriptionService.downloadPath stringByAppendingPathComponent:filename];
    DDLogInfo(@"%@ %@ downloadFilePath=%@", LogTag, self.name, downloadFilename);
    // Record download filename.
    SetLocalValue(@"filename", downloadFilename);
    // Download the content.
    __block IFHTTPClient *client = [IFHTTPUtils getFileFromURL:url offset:0 path:downloadFilename then:^(BOOL ok) {
        client = nil;
        [self contentDownloadCompleted:ok];
    }];
}

- (void)contentDownloadCompleted:(BOOL)ok {
    DDLogInfo(@"EPIncrementalSubscription: %@ content download %@", feedID, ok ? @"completed" : @"failed");
    if (ok) {
        [self unpackContentFromFile:downloadFilename];
    }
    [self finishDownload];
}

// TODO: Analyse potential problems with this code.
// The main danger here is off an incomplete update due to the failure of one of its operations.
// There are two main types of failure:
// * Failure to unpack and copy all files to their correct positions;
// * Failure to fully update the DB state.
// The DB manifest processing code performs the data update within a transaction, so this should ensure
// that either the DB state is updated completely, or not at all.
// The buildid value is only updated after the DB has been successfully updated, so if the DB update does
// fail for any reason, then the app will request updates from the old/previous build ID the next time the
// subscription is refreshed, which will ensure that - eventually - the data will become synchronized with
// the server state.
// File deletions are only performed after a successful DB update. This ensures that any files referenced
// by the old DB data will still be in place.
// So the main danger is of a partially completed file update, combined with a full DB update. This could
// result in new files being referenced by new DB records, which have failed to be written to the file
// system.
// Only performing the DB update if the file update completes with no errors improves situation, as it
// avoids a situation where new posts in the DB are referencing new files which failed to unpack; however,
// there is still the possibility of a partially completed unpack operation which leaves broken files or
// hanging references from successfully unpacked files. A proper solution here would require the following
// to be done:
// 1. Create a complete copy of the current content under the subs dir;
// 2. Unpack the zip to the copy location;
// 3. If the unpack succeeds, then -
//    - Rename the original dir;
//    - Move the new dir to the original location;
//    - Delete the moved, original content.
// Step (1) can be expensive; Step (3) may fail in a number of ways, and would be simpler and more reliable
// if done using symlinks, but this isn't an option on Android.
- (void)unpackContentFromFile:(NSString *)contentZipPath {
    NSString *manifestFilePath;
    id manifestData;
    BOOL ok = NO;
    @try {
        // Signal that the update is about to start.
        [self.subscriptionService subscription:self updating:YES];
        // Unpack the specified zip file.
        if ([IFFileIO unzipFileAtPath:contentZipPath toPath:contentDirPath]) {
            // Read the build content manifest from the unpacked data.
            manifestFilePath = [contentDirPath stringByAppendingPathComponent:@"manifest.json"];
            if ([fileManager fileExistsAtPath:manifestFilePath]) {
                manifestData = [IFFileIO readJSONFromFileAtPath:manifestFilePath encoding:NSUTF8StringEncoding];
                if (!manifestData) {
                    DDLogWarn(@"%@ Failed to read data from manifest at %@", LogTag, manifestFilePath);
                }
                else {
                    ok = YES;
                }
            }
            else {
                DDLogWarn(@"%@ Content manifest not found at %@", LogTag, manifestFilePath);
            }
        }
    }
    @catch(NSException *e) {
        DDLogError(@"%@ Error unpacking content from %@: %@", LogTag, contentZipPath, e);
    }
    @finally {
        // Signal that the update has completed.
        [self.subscriptionService subscription:self updating:NO];
    }
    
    // Process manifest data if file unpack succeeded, and manifest data found.
    if (ok) {
        // Check that feed ID is correct.
        NSString *manifestFeedID = [manifestData valueForKey:@"feedid"];
        if ([feedID isEqualToString:manifestFeedID]) {
            // Check for DB updates in manifest.
            NSDictionary *db = [manifestData valueForKey:@"db"];
            if (db) {
                IFResource *rsc = [self.subscriptionService getResourceForPath:manifestFilePath];
                EPDBManifestProcessor *manifestProc = [[EPDBManifestProcessor alloc] initWithData:db resource:rsc];
                ok = [manifestProc process];
            }
        }
        else {
            DDLogWarn(@"%@ Feed ID mismatch in manifest at %@ (%@/%@)", LogTag, manifestFilePath, feedID, manifestFeedID);
        }
    }

    // If manifest data processed successfully then record its build ID, process file deletions.
    if (ok) {
        // If the database update didn't fail then record the build ID.
        NSString *buildid = [manifestData valueForKey:@"buildid"];
        if (buildid) {
            SetLocalValue(@"buildid", buildid);
            // Schedule file deletions. "deletions" is assumed to be an array of filename strings.
            NSArray *deletions = [manifestData valueForKey:@"deletions"];
            if (deletions && [deletions count] > 0) {
                for (NSString *filename in deletions) {
                    NSString *path = [contentDirPath stringByAppendingPathComponent:filename];
                    [fileManager removeItemAtPath:path error:nil];
                }
                DDLogInfo(@"%@ Deleted %ld files from %@", LogTag, (unsigned long)[deletions count], contentDirPath);
            }
        }
        else {
            DDLogWarn(@"%@ No build ID found in manifest %@", LogTag, manifestFilePath);
        }
    }
    
    // Notify observers
    IFCompoundURI *uri = [self.subscriptionService getSubsURIForPath:contentDirPath];
    [[EPCore getCore].mvc notifyResourceObserversOfURI:uri];
}

- (void)finishDownload {
    if (downloadFilename) {
        [fileManager removeItemAtPath:downloadFilename error:nil];
        downloadFilename = nil;
    }
    RemoveLocalValue(@"url");
    RemoveLocalValue(@"filename");
    RemoveLocalValue(@"status");
}

@end
