//
//  EPDBController.m
//  EPCore
//
//  Created by Julian Goacher on 25/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPDBController.h"
#import "EPCore.h"
#import "IFCore.h"
#import "NSArray+IF.h"
#import "NSDictionary+IF.h"

static const int ddLogLevel = IFCoreLogLevel;

#define Tag @"EPDBController"

@interface EPDBController()

- (NSDictionary *)readRecordWithID:(NSString *)identifier fromTable:(NSString *)table db:(id<PLDatabase>)db;
- (NSDictionary *)readRecordWithID:(NSString *)identifier idColumn:(NSString *)idColumn fromTable:(NSString *)table db:(id<PLDatabase>)db;
- (NSDictionary *)readRowFromResultSet:(id<PLResultSet>)rs;
- (BOOL)updateValues:(NSDictionary *)values inTable:(NSString *)table db:(id<PLDatabase>)db;
- (BOOL)updateValues:(NSDictionary *)values idColumn:(NSString *)idColumn inTable:(NSString *)table db:(id<PLDatabase>)db;
- (BOOL)deleteIDs:(NSArray *)identifiers idColumn:(NSString *)idColumn fromTable:(NSString *)table;

@end

@implementation EPResourceObserverNotifier

- (id)initWithController:(EPController *)_controller {
    self = [super init];
    if (self) {
        controller = _controller;
    }
    return self;
}

- (void)notifyResourceObserversOfTablePath:(NSString *)path {
    [controller notifyResourceObserversOfScheme:@"db" path:path];
}

@end

@implementation EPDBController

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        configuration = [config getValueAsConfiguration:@"db" defaultValue:[EPConfiguration emptyConfiguration]];
        dbHelper = [[EPDBHelper alloc] initWithConfiguration:configuration];
        dbHelper.controller = self;
        // Build lookup table of column tags.
        NSMutableDictionary *tags = [[NSMutableDictionary alloc] init];
        NSDictionary *tablesConfig = [configuration getValueAsConfigurationMap:@"tables"];
        for (id tname in [tablesConfig allKeys]) {
            EPConfiguration *tableConfig = [tablesConfig objectForKey:tname];
            NSMutableDictionary *columns = [[NSMutableDictionary alloc] init];
            NSDictionary *columnsConfig = [tableConfig getValueAsConfigurationMap:@"columns"];
            for (id cname in [columnsConfig allKeys]) {
                EPConfiguration *colConfig = [columnsConfig objectForKey:cname];
                NSString *tag = [colConfig getValueAsString:@"tag"];
                if (tag) {
                    [columns setObject:cname forKey:tag];
                }
            }
            [tags setObject:columns forKey:tname];
        }
        taggedTableColumns = tags;
    }
    return self;
}

- (BOOL)beginTransaction {
    NSError *error = nil;
    id<PLDatabase> db = [dbHelper getDatabase];
    BOOL ok = [db beginTransactionAndReturnError:&error];
    if (error) {
        DDLogError(@"%@ Failed to begin transaction: %@", Tag, error );
    }
    return ok;
}

- (BOOL)commitTransaction {
    NSError *error = nil;
    id<PLDatabase> db = [dbHelper getDatabase];
    BOOL ok = [db commitTransactionAndReturnError:&error];
    if (error) {
        DDLogError(@"%@ Failed to commit transaction: %@", Tag, error );
    }
    return ok;
}

- (BOOL)rollbackTransaction {
    NSError *error = nil;
    id<PLDatabase> db = [dbHelper getDatabase];
    BOOL ok = [db rollbackTransactionAndReturnError:&error];
    if (error) {
        DDLogError(@"%@ Failed to rollback transaction: %@", Tag, error );
    }
    return ok;
}

- (NSString *)getColumnWithTag:(NSString *)tag fromTable:(NSString *)table {
    NSDictionary *columns = [taggedTableColumns valueForKey:table];
    return [columns valueForKey:tag];
}

- (NSDictionary *)readRecordWithID:(NSString *)identifier fromTable:(NSString *)table {
    id<PLDatabase> db = [dbHelper getDatabase];
    return [self readRecordWithID:identifier fromTable:table db:db];
}

- (NSDictionary *)readRecordWithID:(NSString *)identifier fromTable:(NSString *)table db:(id<PLDatabase>)db {
    NSDictionary *result = nil;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
    if (idColumn) {
        result = [self readRecordWithID:identifier idColumn:idColumn fromTable:table db:db];
    }
    else {
        DDLogWarn(@"%@ No ID column found for table %@", Tag, table );
    }
    return result;
}

- (NSDictionary *)readRecordWithID:(NSString *)identifier idColumn:(NSString *)idColumn fromTable:(NSString *)table db:(id<PLDatabase>)db {
    NSDictionary *result = nil;
    if (identifier) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=?", table, idColumn];
        NSArray *params = @[ identifier ];
        id<PLPreparedStatement> statement = [db prepareStatement:sql];
        [statement bindParameters:params];
        id<PLResultSet> rs = [statement executeQuery];
        // TODO: Assuming here that the result set is initially positioned before the first row.
        if ([rs next]) {
            result = [self readRowFromResultSet:rs];
        }
        [rs close];
        [statement close];
    }
    else {
        DDLogWarn(@"%@ No identifier passed to readRecordWithID:", Tag);
    }
    return result;
}

- (NSArray *)performQuery:(NSString *)sql withParams:(NSArray *)params {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    id<PLDatabase> db = [dbHelper getDatabase];
    id<PLPreparedStatement> statement = [db prepareStatement:sql];
    [statement bindParameters:params];
    id<PLResultSet> rs = [statement executeQuery];
    while ([rs next]) {
        [result addObject:[self readRowFromResultSet:rs]];
    }
    [rs close];
    [statement close];
    return result;
}

- (NSDictionary *)readRowFromResultSet:(id<PLResultSet>)rs {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    int colCount = [rs getColumnCount];
    for (int i = 0; i < colCount; i++) {
        if (![rs isNullForColumnIndex:i]) {
            NSString *name = [rs nameForColumnIndex:i];
            id value = [rs objectForColumnIndex:i];
            [result setObject:value forKey:name];
        }
    }
    return result;
}

- (BOOL)insertValueList:(NSArray *)valueList intoTable:(NSString *)table {
    id<PLDatabase> db = [dbHelper getDatabase];
    BOOL result = YES;
    for (NSDictionary *values in valueList) {
        result &= [self insertValues:values intoTable:table db:db];
    }
    [notifier notifyResourceObserversOfTablePath:table];
    return result;
}

- (BOOL)insertValues:(NSDictionary *)values intoTable:(NSString *)table {
    id<PLDatabase> db = [dbHelper getDatabase];
    BOOL result = [self insertValues:values intoTable:table db:db];
    [notifier notifyResourceObserversOfTablePath:table];
    return result;
}

- (BOOL)insertValues:(NSDictionary *)values intoTable:(NSString *)table db:(id<PLDatabase>)db {
    BOOL result = YES;
    NSArray *keys = [NSArray arrayWithDictionaryKeys:values];
    if ([keys count] > 0) {
        NSArray *params = [NSArray arrayWithItem:@"?" repeated:[keys count]];
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", table, [keys joinWithSeparator:@","], [params joinWithSeparator:@","]];
        id<PLPreparedStatement> statement = [db prepareStatement:sql];
        [statement bindParameters:[NSArray arrayWithDictionaryValues:values forKeys:keys]];
        result = [statement executeUpdate];
        [statement close];
    }
    return result;
}

- (BOOL)updateValues:(NSDictionary *)values inTable:(NSString *)table {
    id<PLDatabase> db = [dbHelper getDatabase];
    BOOL result = [self updateValues:values inTable:table db:db];
    if (result) {
        [notifier notifyResourceObserversOfTablePath:table];
    }
    else {
        NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
        id identifier = [values valueForKey:idColumn];
        DDLogWarn(@"%@ Update failed %@ %@", Tag, table, identifier );
    }
    return result;
}

- (BOOL)updateValues:(NSDictionary *)values inTable:(NSString *)table db:(id<PLDatabase>)db {
    BOOL result = NO;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
    if (idColumn) {
        result = [self updateValues:values idColumn:idColumn inTable:table db:db];
    }
    else {
        DDLogWarn(@"%@ No ID column found for table %@", Tag, table );
    }
    return result;
}

- (BOOL)updateValues:(NSDictionary *)values idColumn:(NSString *)idColumn inTable:(NSString *)table db:(id<PLDatabase>)db {
    NSArray *keys = [NSArray arrayWithDictionaryKeys:values];
    NSMutableArray *fields = [[NSMutableArray alloc] initWithCapacity:[keys count]];
    NSMutableArray *params = [[NSMutableArray alloc] initWithCapacity:[keys count] + 1];
    for (id key in keys) {
        [fields addObject:[NSString stringWithFormat:@"%@=?", key]];
        [params addObject:[values valueForKey:key]];
    }
    id identifier = [values valueForKey:idColumn];
    [params addObject:identifier];
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@=?", table, [fields joinWithSeparator:@","], idColumn ];
    id<PLPreparedStatement> statement = [db prepareStatement:sql];
    [statement bindParameters:params];
    BOOL result = [statement executeUpdate];
    [statement close];
    return result;
}

- (BOOL)mergeValueList:(NSArray *)valueList intoTable:(NSString *)table {
    BOOL result = YES;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
    if (idColumn) {
        id<PLDatabase> db = [dbHelper getDatabase];
        for (NSDictionary *values in valueList) {
            id identifier = [values valueForKey:idColumn];
            NSDictionary *record = [self readRecordWithID:identifier fromTable:table];
            if (record) {
                record = [record extendWith:values];
                result &= [self updateValues:record idColumn:idColumn inTable:table db:db];
            }
            else {
                result &= [self insertValues:values intoTable:table db:db];
            }
        }
        [notifier notifyResourceObserversOfTablePath:table];
    }
    else {
        DDLogWarn(@"%@ No ID column found for table %@", Tag, table );
    }
    return result;
}

- (BOOL)deleteIDs:(NSArray *)identifiers fromTable:(NSString *)table {
    BOOL result = NO;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
    if (idColumn) {
        result = [self deleteIDs:identifiers idColumn:idColumn fromTable:table];
    }
    else {
        DDLogWarn(@"%@ No ID column found for table %@", Tag, table );
    }
    return result;
}

- (BOOL)deleteIDs:(NSArray *)identifiers idColumn:(NSString *)idColumn fromTable:(NSString *)table {
    BOOL result = NO;
    if ([identifiers count]) {
        id<PLDatabase> db = [dbHelper getDatabase];
        NSArray *params = [NSArray arrayWithItem:@"?" repeated:[identifiers count]];
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ IN (%@)", table, idColumn, [params joinWithSeparator:@","]];
        id<PLPreparedStatement> statement = [db prepareStatement:sql];
        [statement bindParameters:identifiers];
        result = [statement executeUpdate];
        [statement close];
        [notifier notifyResourceObserversOfTablePath:table];
    }
    return result;
}

- (BOOL)deleteFromTable:(NSString *)table where:(NSString *)where {
    id<PLDatabase> db = [dbHelper getDatabase];
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@", table, where];
    return [db executeUpdate:sql];
}

- (void)startService {
    EPController *mvc = [EPCore getCore].mvc;
    notifier = [[EPResourceObserverNotifier alloc] initWithController:mvc];
    BOOL resetDatabase = [configuration getValueAsBoolean:@"resetDatabase" defaultValue:NO];
    if (resetDatabase) {
        NSString *dbName = [configuration getValueAsString:@"name"];
        DDLogWarn(@"%@ Resetting %@ database...", Tag, dbName);
        [dbHelper deleteDatabase];
    }
    [dbHelper getDatabase];
}

- (void)stopService {}

- (EPDBController *)startBatchedNotificationUpdates {
    EPDBController *result = [[EPDBController alloc] init];
    // NOTE: From a memory management point of view, this following code probably isn't safe as it doesn't
    // include ARC management; in normal usage of this class, this shouldn't be an issue as the object returned
    // by this method should be disposed of whithin the lifetime of the parent object instance.
    // However, if the instance returned here was used after the parent had been destroyed, then there would
    // probably be a crash because of illegal memory access.
    result->notifier = [[EPBatchedResourceObserverNotifier alloc] initWithNotifier:notifier];
    result->dbHelper = dbHelper;
    result->configuration = configuration;
    result->taggedTableColumns = taggedTableColumns;
    return result;
}

- (void)sendQueuedNotifications {
    if ([notifier isKindOfClass:[EPBatchedResourceObserverNotifier class]]) {
        [(EPBatchedResourceObserverNotifier *)notifier sendQueuedNotifications];
    }
}

@end

@implementation EPBatchedResourceObserverNotifier

- (id)initWithNotifier:(EPResourceObserverNotifier *)_notifer {
    self = [super init];
    if (self) {
        notifier = _notifer;
        queuedNotifications = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)notifyResourceObserversOfTablePath:(NSString *)path {
    [queuedNotifications addObject:path];
}

- (void)sendQueuedNotifications {
    // Sort the array of paths.
    NSArray *paths = [queuedNotifications sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    // Issue unique notifications.
    NSString *prevPath = nil;
    for (NSString *path in paths) {
        if (![prevPath isEqualToString:path]) {
            [notifier notifyResourceObserversOfTablePath:path];
            prevPath = path;
        }
    }
    // Clear the list of queued notifications.
    [queuedNotifications removeAllObjects];
}

@end
