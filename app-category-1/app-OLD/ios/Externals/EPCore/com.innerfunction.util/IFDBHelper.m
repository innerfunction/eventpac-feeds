//
//  IFDBHelper.m
//  EPCore
//
//  Created by Julian Goacher on 25/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "IFDBHelper.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

NSString *getDatabasePath(NSString *databaseName) {
    // See http://stackoverflow.com/questions/11252173/ios-open-sqlite-database
    // Need to review whether this is the best/correct location for the db.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", databaseName]];
}

@implementation IFDBHelper

- (id)initWithName:(NSString *)name version:(int)version {
    self = [super init];
    if (self) {
        databaseName = name;
        databaseVersion = version;
        NSString *path = getDatabasePath( databaseName );
        connectionProvider = [[PLSqliteConnectionProvider alloc] initWithPath:path];
    }
    return self;
}

- (BOOL)deleteDatabase {
    BOOL ok = YES;
    NSString *path = getDatabasePath( databaseName );
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (error) {
        DDLogWarn(@"IFDBHelper: Error deleting database at %@: %@", path, error );
        ok = NO;
    }
    return ok;
}

- (id<PLDatabase>)getDatabase {
    id<PLDatabase> result;
    if (database && [database goodConnection]) {
        result = database;
    }
    else {
        // TODO: Is this the correct way to instantiate this class?
        PLSqliteMigrationVersionManager *migrationVersionManager = [[PLSqliteMigrationVersionManager alloc] init];
        // TODO: Is this the correct way to instantiate & invoke this class? Will it work correctly if no migration is necessary?
        PLDatabaseMigrationManager *migrationManager
            = [[PLDatabaseMigrationManager alloc] initWithConnectionProvider:connectionProvider
                                                          transactionManager:migrationVersionManager
                                                              versionManager:migrationVersionManager
                                                                    delegate:self];
        NSError *error = nil;
        if ([migrationManager migrateAndReturnError:&error]) {
            // TODO: Will previous method close its db connection on exit?
            result = [connectionProvider getConnectionAndReturnError:&error];
            if (error) {
                DDLogError(@"IFDBHelper: Failed to open connection: %@", [error localizedDescription]);
            }
        }
        else {
            if (error) {
                // TODO
                DDLogError(@"IFDBHelper: Failed to migrate database: %@", [error localizedDescription]);
            }
        }
    }
    database = result;
    return result;
}

- (void)close {
    [database close];
    database = nil;
}

- (BOOL)migrateDatabase:(id<PLDatabase>)db currentVersion:(int)currentVersion newVersion:(int *)newVersion error:(NSError *__autoreleasing *)outError {
    if (currentVersion == 0) {
        [self.delegate onCreate:db];
    }
    else if (currentVersion < databaseVersion) {
        [self.delegate onUpgrade:db from:currentVersion to:databaseVersion];
    }
    *newVersion = databaseVersion;
    return YES;
}

@end
