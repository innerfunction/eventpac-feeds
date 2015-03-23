//
//  EPDSValueAdapter.h
//  EPCore
//
//  Created by Julian Goacher on 15/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFStringTemplate.h"
#import "EPConfiguration.h"

@class EPDSValueAdapterResult;

// A generic value adapter.
@interface EPDSValueAdapter : NSObject

// The name of the result property this adapter is bound to.
@property (nonatomic, strong) NSString *name;

- (id)initWithName:(NSString *)name;
- (id)mapValuesWithValue:(NSDictionary *)values;

+ (EPDSValueAdapterResult *)adapterForConfiguration:(EPConfiguration *)config;

@end

@interface EPDSValueAdapterResult : EPDSValueAdapter

- (NSDictionary *)mapResultWithValue:(NSDictionary *)values;

@end

@interface EPDSValueAdapterSet : EPDSValueAdapterResult {
    NSArray *resultValueAdapters;
}

- (id)initWithConfiguration:(EPConfiguration *)config;
- (id)initWithName:(NSString *)name configuration:(EPConfiguration *)config;

@end

// A value adapter mapping a single DB column to the result.
@interface EPDSValueAdapterColumn : EPDSValueAdapter {
    NSString *columnName;
}

- (id)initWithName:(NSString *)name columnName:(NSString *)columnName;

@end

// A value adapter for generating a value result from a string template.
@interface EPDSValueAdapterTemplate : EPDSValueAdapter {
    IFStringTemplate *stringTemplate;
}

- (id)initWithName:(NSString *)name template:(NSString *)_template;

@end

// A value adapter for generating a value result from a URI.
@interface EPDSValueAdapterURI : EPDSValueAdapterTemplate

- (id)initWithName:(NSString *)name uri:(NSString *)uri;

@end