//
//  EPDataSource.m
//  EPCore
//
//  Created by Julian Goacher on 28/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPDataSource.h"
#import "NSString+IF.h"
#import "EPCore.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

#define LogTag @"EPDataSource:"

@implementation EPDataSource

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        if ([config hasValue:@"sql"]) {
            sql = [config getValueAsString:@"sql"];
            NSString *_sql = [sql lowercaseString];
            // Extract the 'from' clause from the SQL statement and use to construct the list of table dependencies.
            NSInteger idx0 = [_sql indexOf:@"from "];
            NSInteger idx1 = [_sql indexOf:@"where "];
            if( idx1 == -1 ) {
                idx1 = [_sql indexOf:@"order by "];
            }
            if( idx1 == -1 ) {
                idx1 = [_sql indexOf:@"group by "];
            }
            if( idx1 == -1 ) {
                idx1 = [_sql length];
            }
            // TODO: Note that this assumes a simple comma-delimited list of table names, doesn't allow for tables
            // renamed using 'as'.
            if( idx0 > -1 && idx0 < idx1 ) {
                // Trim whitespace from list of tables before tokenizing.
                NSString *tables = [[_sql substringFromIndex:idx0 + 5 toIndex:idx1] stringByTrimmingCharactersInSet:
                                   [NSCharacterSet whitespaceCharacterSet]];
                self.dependencies = [tables split:@"\\s*,\\s*"];
            }
            else {
                DDLogWarn(@"%@ Table dependencies not found in SQL %@", LogTag, sql );
                self.dependencies = [NSArray array];
            }
        }
        else if ([config hasValue:@"table"]) {
            // Allow a single-table data source to be specified as follows:
            //  {
            //      "table":    "<table name>",
            //      "filter": {
            //          "column1":  "value1",       # Implied string equality comparison
            //          "column2":  "> 10"
            //      }
            //
            NSMutableArray *terms = [[NSMutableArray alloc] init];
            [terms addObject:@"SELECT * FROM"];
            NSString *tableName = [config getValueAsString:@"table"];
            [terms addObject:tableName];
            NSDictionary *filter = [config getValue:@"filter"];
            if (filter) {
                [terms addObject:@"WHERE"];
                // Regex pattern for detecting filter values that contain a predicate.
                IFRegExp *predicatePattern = [[IFRegExp alloc] initWithPattern:@"^\\s*(=|<|>|LIKE\\s|NOT\\s)"];
                BOOL and = NO;
                for (NSString *filterName in [filter keyEnumerator]) {
                    if (and) {
                        [terms addObject:@"AND"];
                    }
                    [terms addObject:filterName];
                    NSString *filterValue = [filter valueForKey:filterName];
                    if ([predicatePattern matches:filterValue]) {
                        [terms addObject:filterValue];
                    }
                    else if ([filterValue hasPrefix:@"?"]) {
                        // ? prefix indicates a parameterized value; don't quote in the SQL.
                        [terms addObject:[NSString stringWithFormat:@"= %@", filterValue]];
                    }
                    else {
                        [terms addObject:[NSString stringWithFormat:@"= '%@'", filterValue]];
                    }
                    and = YES;
                }
            }
            sql = [terms componentsJoinedByString:@" "];
            argNames = @[];
            self.dependencies = @[ tableName ];
        }
        else {
            DDLogWarn(@"%@ No SQL or table filter specified", LogTag);
        }
        
        if (sql) {
            // Read list of argument names in defined order. Arguments are defined in the SQL statement as ?xxx,
            // where 'xxx' is the argument name.
            NSMutableArray *_argNames = [[NSMutableArray alloc] init];
            IFRegExp *re = [[IFRegExp alloc] initWithPattern:@"\\?(\\w+)(.*)"];
            NSArray *groups = [re match:sql];
            while ([groups count]) {
                [_argNames addObject:[groups objectAtIndex:1]];
                groups = [re match:[groups objectAtIndex:2]];
            }
            argNames = _argNames;
            // Replace all argument placeholders with just '?' in the SQL.
            sql = [sql replaceAllOccurrences:@"\\?\\w+" with:@"?"];
        }

        // Instantiate the result adapter.
        EPCore *core = [EPCore getCore];
        EPConfiguration *adapterConfig = [config getValueAsConfiguration:@"adapter"];
        if (adapterConfig) {
            resultAdapter = (id<EPDSResultAdapter>)[core makeComponentWithConfiguration:adapterConfig identifier:@"adapter"];
        }
    }
    return self;
}

- (id)readDataWithController:(EPDBController *)controller params:(NSDictionary *)params {
    NSMutableArray *args = [[NSMutableArray alloc] init];
    for (NSString *name in argNames) {
        id value = [params valueForKey:name];
        if (value != nil) {
            [args addObject:value];
        }
        else {
            // TODO: Need to confirm that this will work as expected...
            [args addObject:[NSNull null]];
        }
    }
    id result = [controller performQuery:sql withParams:args];
    return resultAdapter ? [resultAdapter mapResult:result] : result;
}

@end
