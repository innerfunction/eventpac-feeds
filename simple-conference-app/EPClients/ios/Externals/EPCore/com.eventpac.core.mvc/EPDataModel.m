//
//  EPDataModel.m
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPDataModel.h"
#import "EPDefaultFormatter.h"

@implementation EPDataModel

- (id)initWithPathSeparator:(NSString *)separator {
    self = [super initWithPathSeparator:separator];
    if (self) {
        implicitViews = [[NSMutableDictionary alloc] init];
        formatters = [[NSMutableDictionary alloc] init];
        defaultFormatter = [[EPDefaultFormatter alloc] init];
    }
    return self;
}

- (void)setValue:(id)value forPath:(NSString *)path {}

- (id<EPFormatter>)getFormatterForPath:(NSString *)path {
    id<EPFormatter> formatter = [formatters objectForKey:path];
    return formatter ? formatter : defaultFormatter;
}

- (void)addFormatter:(id<EPFormatter>)formatter forPath:(NSString *)path {
    [formatters setObject:formatter forKey:path];
}

@end
