//
//  EPDefaultFormatter.m
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPDefaultFormatter.h"

@implementation EPDefaultFormatter

- (NSString *)formatValue:(id)value {
    return value ? [value description] : @"";
}

- (id)parseValue:(NSString *)value {
    return value;
}

@end
