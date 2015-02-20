//
//  EPDBManifestProcessor.m
//  EPCore
//
//  Created by Julian Goacher on 01/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPDBManifestProcessor.h"
#import "EPCore.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

@implementation EPDBManifestProcessor

- (id)initWithData:(NSDictionary *)data resource:(IFResource *)resource {
    return [self initWithConfiguration:[[EPConfiguration alloc] initWithData:data resource:resource]];
}

- (id)initWithConfiguration:(EPConfiguration *)_configuration {
    self = [super init];
    if (self) {
        configuration = _configuration;
        dbController = [EPCore getCore].mvc.dbController;
    }
    return self;
}

- (BOOL)process {
    BOOL ok = NO;
    NSArray *tableNames = [configuration getValueNames];
    if (![tableNames count]) {
        DDLogWarn(@"EPDBManifestProcessor: No table names defined in DB manifest");
        ok = YES; // No updates, no errors.
    }
    else {
        // Start a batched notification update.
        EPDBController *dbc = [dbController startBatchedNotificationUpdates];
        @try {
            [dbc beginTransaction];
            // Process updates for each table.
            for (NSString *tableName in tableNames) {
                EPConfiguration *tableChanges = [configuration getValueAsConfiguration:tableName];

                ok = YES; // Assume everything ok at this point.
                
                // Perform garbage collection.
                NSString *gc = [tableChanges getValueAsString:@"gc"];
                if (gc) {
                    ok = [dbc deleteFromTable:tableName where:gc];
                }
                if (!ok) break;
                
                // Delete records with the specified ID.
                NSArray *deletes = (NSArray *)[tableChanges getValue:@"deletes"];
                if ([deletes count]) {
                    ok = [dbc deleteIDs:deletes fromTable:tableName];
                    DDLogInfo(@"EPDBManifestProcessor: Deleted %lu records from table %@", (unsigned long)[deletes count], tableName);
                }
                if (!ok) break;
                
                // Perform insertions/updates.
                NSArray *updates = (NSArray *)[tableChanges getValue:@"updates"];
                if ([updates count]) {
                    ok = [dbc mergeValueList:updates intoTable:tableName];
                    if (ok) {
                        // NOTE: Log reporting here is slightly different from Android version.
                        DDLogInfo(@"EPDBManifestProcessor: Merged %lu records into table %@", (unsigned long)[updates count], tableName);
                    }
                }
                if (!ok) break;
            }
        }
        @catch (NSException *exception) {
            DDLogError(@"EPDBManifestProcessor: Error processing manifest: %@", exception);
        }
        @finally {
            if (ok) {
                DDLogCVerbose(@"EPDBManifestProcessor: Committing DB updates");
                [dbc commitTransaction];
                // Send batched update notifications.
                [dbc sendQueuedNotifications];
            }
            else {
                DDLogCVerbose(@"EPDBManifestProcessor: Updates not ok, rolling back DB updates");
                [dbc rollbackTransaction];
            }
        }
    }
    return ok;
}

@end
