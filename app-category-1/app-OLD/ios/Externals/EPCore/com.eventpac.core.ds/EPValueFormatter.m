//
//  EPValueFormatter.m
//  EPCore
//
//  Created by Julian Goacher on 23/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPValueFormatter.h"
#import "IFTypeConversions.h"
#import "ISO8601DateFormatter.h"
#import "NSString+IF.h"

@interface EPDateValueFormatter : EPValueFormatter {
    ISO8601DateFormatter *dateParser;
}

@end

@interface EPNumberValueFormatter : EPValueFormatter {
    NSNumberFormatter *numberParser;
}

@end

typedef id (^EPValueFormatterBlock) (id);

@interface EPBlockValueFormatter : EPValueFormatter {
    EPValueFormatterBlock format;
}

- (id)initWithBlock:(EPValueFormatterBlock)block;

@end

@interface EPDateFormatterWrapper : NSObject {
    NSDate *date;
}

- (id)initWithDate:(NSDate *)date;
- (id)valueForKey:(NSString *)key;

@end

@interface EPNumberFormatterWrapper : NSObject {
    NSNumber *number;
}

- (id)initWithNumber:(NSNumber *)number;
- (id)valueForKey:(NSString *)key;

@end

@implementation EPValueFormatter

- (id)format:(id)value {
    return value;
}

+ (EPValueFormatter *)forType:(NSString *)type {
    if ([@"date" isEqualToString:type]) {
        return [[EPDateValueFormatter alloc] init];
    }
    if ([@"number" isEqualToString:type]) {
        return [[EPNumberValueFormatter alloc] init];
    }
    if ([@"boolean" isEqualToString:type]) {
        return [[EPBlockValueFormatter alloc] initWithBlock:^(id value) {
            BOOL isTrue = NO;
            if ([value isKindOfClass:[NSNumber class]]) {
                isTrue = [(NSNumber *)value intValue] != 0;
            }
            else {
                isTrue = [[value description] isEqualToString:@"true"];
            }
            return isTrue ? @"true" : @"false";
        }];
    }
    if ([@"csv" isEqualToString:type]) {
        return [[EPBlockValueFormatter alloc] initWithBlock:^(id value) {
            return [[value description] split:@","];
        }];
    }
    if ([@"json" isEqualToString:type]) {
        return [[EPBlockValueFormatter alloc] initWithBlock:^(id value) {
            return [IFTypeConversions asJSONData:[value description]];
        }];
    }
    return [[EPValueFormatter alloc] init];
}

@end

@implementation EPDateValueFormatter

- (id)init {
    self = [super init];
    if (self) {
        dateParser = [[ISO8601DateFormatter alloc] init];
    }
    return self;
}

- (id)format:(id)value {
    NSDate *date;
    if ([value isKindOfClass:[NSDate class]]) {
        date = (NSDate *)value;
    }
    else if ([value isKindOfClass:[NSNumber class]]) {
        date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[(NSNumber *)value doubleValue]];
    }
    else {
        date = [dateParser dateFromString:[value description]];
    }
    return [[EPDateFormatterWrapper alloc] initWithDate:date];
}

@end

@implementation EPNumberValueFormatter

- (id)init {
    self = [super init];
    if (self) {
        numberParser = [[NSNumberFormatter alloc] init];
    }
    return self;
}

- (id)format:(id)value {
    NSNumber *number;
    if ([value isKindOfClass:[NSNumber class]]) {
        number = (NSNumber *)value;
    }
    else {
        number = [numberParser numberFromString:[value description]];
    }
    return [[EPNumberFormatterWrapper alloc] initWithNumber:number];
}

@end

@implementation EPBlockValueFormatter

- (id)initWithBlock:(EPValueFormatterBlock)block {
    self = [super init];
    if (self) {
        format = [block copy];
    }
    return self;
}

- (id)format:(id)value {
    return format(value);
}

@end

@implementation EPDateFormatterWrapper

- (id)initWithDate:(NSDate *)_date {
    self = [super init];
    if (self) {
        date = _date;
    }
    return self;
}

- (id)valueForKey:(NSString *)key {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeStyle:NSDateFormatterNoStyle];
    if ([@"time" isEqualToString:key]) {
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        [formatter setDateStyle:NSDateFormatterNoStyle];
    }
    else if ([@"short" isEqualToString:key]) {
        [formatter setDateStyle:NSDateFormatterShortStyle];
    }
    else if ([@"medium" isEqualToString:key]) {
        [formatter setDateStyle:NSDateFormatterMediumStyle];
    }
    else {
        [formatter setDateStyle:NSDateFormatterLongStyle];
    }
    return [formatter stringFromDate:date];
}

- (NSString *)description {
    return [self valueForKey:@"long"];
}

@end

@implementation EPNumberFormatterWrapper

- (id)initWithNumber:(NSNumber *)_number {
    self = [super init];
    if (self) {
        number = _number;
    }
    return self;
}

- (id)valueForKey:(NSString *)key {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    if ([@"integer" isEqualToString:key]) {
        return [formatter stringFromNumber:[NSNumber numberWithInteger:[number integerValue]]];
    }
    if ([@"percent" isEqualToString:key]) {
        [formatter setNumberStyle:NSNumberFormatterPercentStyle];
    }
    return [formatter stringFromNumber:number];
}

- (NSString *)description {
    return [self valueForKey:@"long"];
}

@end