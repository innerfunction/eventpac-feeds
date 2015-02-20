//
//  EPSubscription.m
//  EPCore
//
//  Created by Julian Goacher on 02/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPSubscription.h"
#import "EPCore.h"
#import "IFRegExp.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

// TODO: Should probably use the app bundle ID here - otherwise, potential if multiple eventpac apps installed for them to step on each others toes.
#define DownloadFileName(name,ext)  ([NSString stringWithFormat:@"com.eventpac.sub-%@.%@", name, ext])

NSURL *makeRequestURL(NSString *lastModified, NSString *lastRequested, NSString *url) {
    if (!lastModified) {
        lastModified = @"";
    }
    url = [url stringByReplacingOccurrencesOfString:@"@lastModified" withString:lastModified];
    if (!lastRequested) {
        lastRequested = @"";
    }
    url = [url stringByReplacingOccurrencesOfString:@"@lastRequested" withString:lastRequested];
    return [NSURL URLWithString:url];
}

@implementation EPSubscription

@synthesize name, subscriptionService;

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        configuration = config;
        
        mvc = [EPCore getCore].mvc;
        
        self.subscriptionURL = [config getValueAsString:@"url"];
        refresh = self.subscriptionURL && [config getValueAsBoolean:@"refresh" defaultValue:YES];
        
        localStorage = [NSUserDefaults standardUserDefaults];        
    }
    return self;
}

- (void)startService {
    
    fileManager = self.subscriptionService.fileManager;
    
    // NOTE: self.name is only available after initWithConfiguration is called.
    self.lastModifiedLocalStorageKey = [NSString stringWithFormat:@"%@.%@.last-modified", SubscriptionLocalStorageKeyPrefix, self.name];
    self.lastRequestedLocalStorageKey = [NSString stringWithFormat:@"%@.%@.last-requested", SubscriptionLocalStorageKeyPrefix, self.name];
    
    lastModifiedDate = [self parseHTTPDate:[localStorage stringForKey:self.lastModifiedLocalStorageKey] defaultDate:0];
    
    // Setup the download file path. This is placed in the app's tmp directory.
    NSString *downloadFileName = DownloadFileName(self.name, self.downloadFileExtension);
    downloadFilePath = [self.subscriptionService.downloadPath stringByAppendingPathComponent:downloadFileName];
//    downloadFilePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"tmp"] stringByAppendingPathComponent:downloadFileName];
    DDLogInfo(@"EPSubscription: %@ downloadFilePath=%@", self.name, downloadFilePath);
}

- (void)stopService {
}

- (BOOL)isPeriodic {
    return NO;
}

// Note comment head about NSURLRequest, HEAD and redirects:
// http://sutes.co.uk/2009/12/nsurlconnection-using-head-met.html
- (void)refresh {
    if (!refresh) {
        return;
    }
    NSString* lastModified = [localStorage stringForKey:self.lastModifiedLocalStorageKey];
    NSString* lastRequested = [localStorage stringForKey:self.lastRequestedLocalStorageKey];
    NSURL *requestURL = makeRequestURL(lastModified, lastRequested, self.subscriptionURL);
    DDLogInfo(@"EPSubscription: %@ checking for update at %@", self.name, requestURL);
    
    // See note here about NSURLConnection cacheing: http://blackpixel.com/blog/2012/05/caching-and-nsurlconnection.html
    __block NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:requestURL
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                           timeoutInterval:60];
    [req setHTTPMethod:@"HEAD"];
    NSURLConnectionHandler handler = ^(NSURLResponse* res, NSData* data, NSError* err) {
        BOOL doUpdate = YES;
        NSInteger statusCode = ((NSHTTPURLResponse*)res).statusCode;
        if ( statusCode >= 400 ) {
            DDLogError(@"EPSubscription: %@ Content not available (%ld)", self.name, (long)statusCode);
            doUpdate = NO;
        }
        else {
            NSDictionary* headers = [(NSHTTPURLResponse*)res allHeaderFields];
            lastModifiedHeader = [headers valueForKey:@"Last-Modified"];
            DDLogInfo(@"EPSubscription: %@ content Last-Modified=%@", self.name, lastModifiedHeader);
            lastModifiedDate = [self parseHTTPDate:lastModifiedHeader defaultDate:[[NSDate date] timeIntervalSince1970]];
            if (lastModified) {
                DDLogInfo(@"EPSubscription: %@ content last update=%@", self.name, lastModified);
                NSDate* lastUpdateDate = [self parseHTTPDate:lastModified defaultDate:0];
                NSComparisonResult order = [lastModifiedDate compare:lastUpdateDate];
                doUpdate = (order == NSOrderedDescending);
            }
        }
        if (doUpdate) {
            DDLogInfo(@"EPSubscription: %@ downloading content update...", self.name);
            if ([self prepareForDownload]) {
                if ([fileManager fileExistsAtPath:downloadFilePath]) {
                    [fileManager removeItemAtPath:downloadFilePath error:nil];
                }
                [fileManager createFileAtPath:downloadFilePath contents:nil attributes:nil];
                downloadFileHandle = [NSFileHandle fileHandleForWritingAtPath:downloadFilePath];
                [req setHTTPMethod:@"GET"];
                NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
                [connection start];
            }
        }
    };
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue currentQueue] completionHandler:handler];
}

- (BOOL)prepareForDownload {
    return YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (!downloadFileHandle) {
        DDLogWarn(@"EPSubscription: Received HTTP content but no file handle available");
    }
    else if ([data length] > 0) {
        [downloadFileHandle seekToEndOfFile];
        [downloadFileHandle writeData:data];
    }
}

// NOTE: Sub-classes should call this *after* processing the download, as this will delete the downloaded data.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    DDLogInfo(@"EPSubscription: %@ content download completed", self.name);

    [localStorage setValue:lastModifiedHeader forKey:self.lastModifiedLocalStorageKey];
    [localStorage setValue:[self.subscriptionService currentTimeAs8601String] forKey:self.lastRequestedLocalStorageKey];
    
    NSError *error = nil;
    [fileManager removeItemAtPath:downloadFilePath error:&error];
    if (error) {
        DDLogError(@"EPSubscription: Error deleting download file at path %@: %@", downloadFilePath, error );
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    DDLogError(@"EPSubscription: %@ error download content: %@", self.name, error );
    error = nil;
    [fileManager removeItemAtPath:downloadFilePath error:&error];
    if (error) {
        DDLogError(@"EPSubscription: Error deleting download file at path %@: %@", downloadFilePath, error );
    }
}

- (NSDate *)parseHTTPDate:(NSString *)date defaultDate:(NSTimeInterval)defaultDate {
    if (date) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss z";
        df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        // Attempt to read the timezone from the last date field.
        NSString *timezone = @"GMT";
        IFRegExp *re = [[IFRegExp alloc] initWithPattern:@"\\s(\\w+)$"];
        NSArray *groups = [re match:date];
        if ([groups count]) {
            timezone = [groups objectAtIndex:1];
        }
        df.timeZone = [NSTimeZone timeZoneWithAbbreviation:timezone];
        return [df dateFromString:date];
    }
    return [NSDate dateWithTimeIntervalSince1970:defaultDate];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"name=%@ url=%@ file=%@", self.name, self.subscriptionURL, downloadFilePath];
}

@end
