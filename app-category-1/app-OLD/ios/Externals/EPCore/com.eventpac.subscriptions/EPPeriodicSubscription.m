//
//  EPPeriodicSubscription.m
//  EPCore
//
//  Created by Julian Goacher on 02/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPPeriodicSubscription.h"
#import "IFFileResource.h"
#import "EPDBManifestProcessor.h"
#import "IFFileIO.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

@interface EPPeriodicSubscription()

- (void)unzipSubscriptionFile;
- (BOOL)processManifestFile;
- (void)initializeContentDirectory;
- (void)notifyResourceObservers;

@end

@implementation EPPeriodicSubscription

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super initWithConfiguration:config];
    if (self) {
        self.downloadFileExtension = @"zip";
        zipResource = [config getValueAsResource:@"zip"];
        initializing = NO;
    }
    return self;
}

- (void)startService {
    [super startService];
    
    contentDirPath = [self.subscriptionService contentDirectoryPathForSubscription:self];
    DDLogInfo(@"EPPeriodicSubscription: content directory=%@", contentDirPath);
    
    manifestFilePath = [contentDirPath stringByAppendingPathComponent:@"manifest.json"];
    
    if (!zipResource) {
        DDLogWarn(@"EPPeriodicSubscription: Zip property for subscription %@ not found", self.name);
    }
    else if (![zipResource isKindOfClass:[IFFileResource class]]) {
        DDLogWarn(@"EPPeriodicSubscription: Zip property for subscription %@ must resolve to a file resource", self.name);
    }
    else {
        IFFileResource *zipFileResource = (IFFileResource *)zipResource;
        zipFilePath = zipFileResource.fileDescription.path;
        if (![fileManager fileExistsAtPath:zipFilePath]) {
            DDLogWarn(@"EPPeriodicSubscription: Zip %@ for subscription %@ not found", zipFilePath, self.name );
            zipFilePath = nil;
        }
    }
    
    [self initializeContentDirectory];
}

- (BOOL)isPeriodic {
    return YES;
}

- (BOOL)prepareForDownload {
    return [super prepareForDownload];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self performSelectorInBackground:@selector(unzipSubscriptionFile) withObject:self];
    [super connectionDidFinishLoading:connection];
}

- (void)initializeContentDirectory {
    BOOL initContent = NO;
    if (!contentDirPath) {
        DDLogWarn(@"EPPeriodicSubscription: contentDirPath is nil");
    }
    else if (![fileManager fileExistsAtPath:contentDirPath]) {
        DDLogInfo(@"EPPeriodicSubscription: Creating content directory for subscription %@", self.name);
        initContent = [self.subscriptionService ensureDirectoryAtPath:contentDirPath];
    }
    else {
        //initContent = ![self processManifestFile];
        // Re-initialize content if manifest file not found.
        initContent = ![fileManager fileExistsAtPath:manifestFilePath];
    }
    if (initContent && zipFilePath) {
        initializing = YES;
        [self performSelectorInBackground:@selector(unzipSubscriptionFile) withObject:self];
    }
}

- (void)unzipSubscriptionFile {
    NSDate *start = [NSDate date];
    DDLogInfo(@"EPPeriodicSubscription: Unzipping content for subscription %@...", self.name);
    NSString *filePath = initializing ? zipFilePath : downloadFilePath;
    initializing = NO;
    if ([IFFileIO unzipFileAtPath:filePath toPath:contentDirPath]) {
        [self processManifestFile];
        [self notifyResourceObservers];
        NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:start] / 1000;
        DDLogInfo(@"EPPeriodicSubscription: Content unzipping for subscription %@ took %f secs", self.name, elapsed);
    }
    else {
        DDLogWarn(@"EPPeriodicSubscription: Failed to unzip content for subscription %@", self.name);
    }
}

- (BOOL)processManifestFile {
    BOOL ok = NO;
    if ([fileManager fileExistsAtPath:manifestFilePath]) {
        // TODO: Read char encoding from http response
        id data = [IFFileIO readJSONFromFileAtPath:manifestFilePath encoding:NSUTF8StringEncoding];
        if (!data) {
            DDLogWarn(@"EPPeriodicSubscription: Failed to read data from manifest file at %@", manifestFilePath);
        }
        else {
            IFResource *rsc = [self.subscriptionService getResourceForPath:manifestFilePath];
            EPConfiguration *config = [[EPConfiguration alloc] initWithData:data resource:rsc];
            if ([config getValueType:@"db"] == EPValueTypeObject) {
                EPDBManifestProcessor *manifestProcessor = [[EPDBManifestProcessor alloc] initWithConfiguration:config];
                [manifestProcessor process];
            }
            ok = YES;
        }
    }
    return ok;
}

- (void)notifyResourceObservers {
    IFCompoundURI *uri = [self.subscriptionService getSubsURIForPath:contentDirPath];
    [mvc notifyResourceObserversOfURI:uri];
}

@end
