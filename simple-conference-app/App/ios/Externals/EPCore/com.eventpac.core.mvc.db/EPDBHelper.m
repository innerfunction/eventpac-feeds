//
//  EPDBHelper.m
//  EPCore
//
//  Created by Julian Goacher on 24/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPDBHelper.h"
#import "IFCore.h"
#import "EPDBController.h"

static const int ddLogLevel = IFCoreLogLevel;

@interface EPDBHelper()

- (NSString *)getCreateTableSQLForTable:(NSString *)tableName config:(EPConfiguration *)tableConfig;
- (NSArray *)getAlterTableSQLForTable:(NSString *)tableName config:(EPConfiguration *)tableConfig from:(int)oldVersion to:(int)newVersion;
- (void)dbInitialize:(id<PLDatabase>)db;
- (void)addInitialDataForTable:(NSString *)tableName config:(EPConfiguration *)tableConfig;

@end

@implementation EPDBHelper

- (id)initWithConfiguration:(EPConfiguration *)config {
    // Android: super( -context-, <db name> config.getValueAsString("name"), -cursor factory-, <db version> config.getValueAsNumber("version")
    self = [super initWithName:[config getValueAsString:@"name"] version:[[config getValueAsNumber:@"version"] intValue]];
    if (self) {
        configuration = config;
        initialData = [[NSMutableDictionary alloc] init];
        self.delegate = self; // TODO: Does this cause a retain cycle?
    }
    return self;
}

- (void)onCreate:(id<PLDatabase>)db {
    NSDictionary *tableConfigs = [configuration getValueAsConfigurationMap:@"tables"];
    for (NSString *tableName in [tableConfigs allKeys]) {
        EPConfiguration *tableConfig = [tableConfigs objectForKey:tableName];
        NSString *sql = [self getCreateTableSQLForTable:tableName config:tableConfig];
        [db executeUpdate:sql];
        [self addInitialDataForTable:tableName config:tableConfig];
    }
    [self dbInitialize:db];
}

- (void)onUpgrade:(id<PLDatabase>)db from:(int)oldVersion to:(int)newVersion {
    DDLogInfo(@"EPDBHelper: Migrating DB from version %d to version %d", oldVersion, newVersion);
    NSDictionary *tableConfigs = [configuration getValueAsConfigurationMap:@"tables"];
    for (NSString *tableName in [tableConfigs allKeys]) {
        EPConfiguration *tableConfig = [tableConfigs objectForKey:tableName];
        NSInteger since = [[tableConfig getValueAsNumber:@"since" defaultValue:0] integerValue];
        NSInteger until = [[tableConfig getValueAsNumber:@"until" defaultValue:[NSNumber numberWithInt:newVersion]] integerValue];
        NSArray *sqls = nil;
        if (since < (NSInteger)oldVersion) {
            // Table exists since before the current DB version, so should exist in the current DB.
            if (until < (NSInteger)newVersion) {
                // Table not required in DB version being migrated to, so drop from database.
                NSString *sql = [NSString stringWithFormat:@"DROP TABLE %@ IF EXISTS", tableName];
                sqls = [NSArray arrayWithObject:sql];
            }
            else {
                // Modify table.
                sqls = [self getAlterTableSQLForTable:tableName config:tableConfig from:oldVersion to:newVersion];
            }
        }
        else {
            // => since > oldVersion
            // Table shouldn't exist in the current database.
            if (until < (NSInteger)newVersion) {
                // Table not required in version being migrated to, so no action required.
                continue;
            }
            else {
                // Create table.
                sqls = [NSArray arrayWithObject:[self getCreateTableSQLForTable:tableName config:tableConfig]];
                [self addInitialDataForTable:tableName config:tableConfig];
            }
        }
        for (NSString *sql in sqls) {
            if (![db executeUpdate:sql]) {
                DDLogWarn(@"EPDBHelper: Failed to execute update %@", sql);
            }
        }
    }
    [self dbInitialize:db];
}

- (void)dbInitialize:(id<PLDatabase>)db {
    DDLogInfo(@"EPDBHelper: Initializing database...");
    for (NSString *tableName in [initialData allKeys]) {
        NSArray *data = [initialData objectForKey:tableName];
        for (NSDictionary *values in data) {
            [self.controller insertValues:values intoTable:tableName db:db];
        }
        id<PLResultSet> rs = [db executeQuery:[NSString stringWithFormat:@"select count() from %@", tableName]];
        int32_t count = 0;
        if ([rs next]) {
            count = [rs intForColumnIndex:0];
        }
        [rs close];
        DDLogInfo(@"EPDBHelper: Initializing %@, inserted %d rows", tableName, count);
    }
}

- (void)addInitialDataForTable:(NSString *)tableName config:(EPConfiguration *)tableConfig {
    if ([tableConfig getValueType:@"data"] == EPValueTypeList) {
        [initialData setObject:[tableConfig getValue:@"data" asRepresentation:@"json"] forKey:tableName];
    }
}

- (NSString *)getCreateTableSQLForTable:(NSString *)tableName config:(EPConfiguration *)tableConfig {
    NSMutableString *cols = [[NSMutableString alloc] init];
    NSDictionary *colConfigs = [tableConfig getValueAsConfigurationMap:@"columns"];
    for (NSString *colName in [colConfigs allKeys]) {
        EPConfiguration *colConfig = [colConfigs objectForKey:colName];
        if ([cols length] > 0) {
            [cols appendString:@","];
        }
        [cols appendString:colName];
        [cols appendString:@" "];
        [cols appendString:[colConfig getValueAsString:@"type"]];
    }
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE %@ (%@)", tableName, cols ];
    return sql;
}

- (NSArray *)getAlterTableSQLForTable:(NSString *)tableName config:(EPConfiguration *)tableConfig from:(int)oldVersion to:(int)newVersion {
    NSMutableArray *sqls = [[NSMutableArray alloc] init];
    NSDictionary *colConfigs = [tableConfig getValueAsConfigurationMap:@"columns"];
    for (NSString *colName in [colConfigs allKeys]) {
        EPConfiguration *colConfig = [colConfigs objectForKey:colName];
        NSInteger since = [[colConfig getValueAsNumber:@"since" defaultValue:0] integerValue];
        NSInteger until = [[colConfig getValueAsNumber:@"until" defaultValue:[NSNumber numberWithInt:newVersion]] integerValue];
        // If a column has been added since the current db version, and not disabled before the
        // version being migrated to, then alter the table schema to include the table.
        if (since > oldVersion && !(until < newVersion)) {
            NSString *type = [colConfig getValueAsString:@"type"];
            NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@", tableName, colName, type ];
            DDLogInfo(@"%@", sql );
            [sqls addObject:sql];
        }
    }
    return sqls;
}

@end
