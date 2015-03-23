//
//  EPDSValueAdapter.m
//  EPCore
//
//  Created by Julian Goacher on 15/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPDSValueAdapter.h"
#import "NSDictionary+IF.h"
#import "ISO8601DateFormatter.h"
#import "EPCore.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

@implementation EPDSValueAdapter

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        self.name = name;
    }
    return self;
}

- (id)mapValuesWithValue:(NSDictionary *)values {
    return nil;
}

+ (EPDSValueAdapterResult *)adapterForConfiguration:(EPConfiguration *)config {
    if (config) {
        return [[EPDSValueAdapterSet alloc] initWithConfiguration:config];
    }
    return [[EPDSValueAdapterResult alloc] init];
}

@end

@implementation EPDSValueAdapterResult

- (id)mapValuesWithValue:(NSDictionary *)values {
    return values;
}

- (id)mapResultWithValue:(NSDictionary *)values {
    return [self mapValuesWithValue:values];
}

@end

@implementation EPDSValueAdapterSet

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        NSMutableArray *adapters = [[NSMutableArray alloc] init];
        NSString *sconfig;
        for (NSString *name in [config getValueNames]) {
            switch ([config getValueType:name]) {
                case EPValueTypeString:
                    sconfig = [config getValueAsString:name];
                    if ([sconfig hasPrefix:@"="]) {
                        [adapters addObject:[[EPDSValueAdapterColumn alloc] initWithName:name columnName:sconfig]];
                    }
                    else if ([sconfig hasPrefix:@"@"]) {
                        // TODO: The value URI will somehow have to be included in the list of data source dependencies.
                        [adapters addObject:[[EPDSValueAdapterURI alloc] initWithName:name uri:sconfig]];
                    }
                    else {
                        [adapters addObject:[[EPDSValueAdapterTemplate alloc] initWithName:name template:sconfig]];
                    }
                    break;
                case EPValueTypeObject:
                    [adapters addObject:[[EPDSValueAdapterSet alloc] initWithName:name configuration:[config getValueAsConfiguration:name]]];
                    break;
                default:
                    DDLogWarn(@"EPDSValueAdapterSet: Skipping value config %@", name);
                    break;
            }
        }
        resultValueAdapters = adapters;
    }
    return self;
}

- (id)initWithName:(NSString *)name configuration:(EPConfiguration *)config {
    self = [self initWithConfiguration:config];
    if (self) {
        self.name = name;
    }
    return self;
}

- (id)mapValuesWithValue:(NSDictionary *)values {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    // Generate output result.
    for (EPDSValueAdapter *adapter in resultValueAdapters) {
        id value = [adapter mapValuesWithValue:values];
        if (value != nil) {
            [result setObject:value forKey:adapter.name];
        }
    }
    return result;
}

@end

@implementation EPDSValueAdapterColumn

- (id)initWithName:(NSString *)name columnName:(NSString *)_columnName {
    self = [super initWithName:name];
    if (self) {
        columnName = [_columnName substringFromIndex:1];
    }
    return self;
}

- (id)mapValuesWithValue:(NSDictionary *)values {
    return [values valueForKey:columnName];
}

@end

@implementation EPDSValueAdapterTemplate

- (id)initWithName:(NSString *)_name template:(NSString *)_template {
    self = [super initWithName:_name];
    if (self) {
        stringTemplate = [[IFStringTemplate alloc] initWithString:_template];
    }
    return self;
}

- (id)mapValuesWithValue:(NSDictionary *)values {
    return [stringTemplate render:values];
}

@end

@implementation EPDSValueAdapterURI

- (id)initWithName:(NSString *)name uri:(NSString *)uri {
    return [super initWithName:name template:[uri substringFromIndex:1]];
}

- (id)mapValuesWithValue:(NSDictionary *)values {
    NSString *uri = (NSString *)[super mapValuesWithValue:values];
    IFResource *r = [[EPCore getCore] resolveURIFromString:uri];
    return [r asJSONData];
}

@end
