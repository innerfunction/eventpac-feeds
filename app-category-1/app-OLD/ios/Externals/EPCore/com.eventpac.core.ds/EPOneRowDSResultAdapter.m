//
//  EPOneRowDSResultAdapter.m
//  EPCore
//
//  Created by Julian Goacher on 15/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPOneRowDSResultAdapter.h"
#import "IFCore.h"
#import "EPValueFormatter.h"
#import "EPI18nMap.h"

static const int ddLogLevel = IFCoreLogLevel;

@implementation EPOneRowDSResultAdapter

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        
        NSMutableDictionary *valueFormatters = [[NSMutableDictionary alloc] init];
        EPConfiguration *formattersConfig = [config getValueAsConfiguration:@"formatters"];
        for (NSString *name in [formattersConfig getValueNames]) {
            NSString *type = [formattersConfig getValueAsString:name];
            [valueFormatters setObject:[EPValueFormatter forType:type] forKey:name];
        }
        inputValueFormatters = valueFormatters;
        
        EPConfiguration *valuesConfig = [config getValueAsConfiguration:@"values"];
        resultValueAdapter = [EPDSValueAdapter adapterForConfiguration:valuesConfig];
    }
    return self;
}

- (id)mapResult:(NSArray *)result {
    return [result count] > 0 ? [self mapResultRow:[result objectAtIndex:0]] : nil;
}

- (NSDictionary *)mapResultRow:(NSDictionary *)row {
    NSMutableDictionary *inputs = [[NSMutableDictionary alloc] initWithDictionary:row];
    [inputs setObject:[EPI18nMap instance] forKey:@"i18n"];
    // Format incoming values.
    for (id key in [inputValueFormatters allKeys]) {
        EPValueFormatter *formatter = [inputValueFormatters objectForKey:key];
        [inputs setObject:[formatter format:[row objectForKey:key]] forKey:key];
    }
    return [resultValueAdapter mapResultWithValue:inputs];
}

@end
