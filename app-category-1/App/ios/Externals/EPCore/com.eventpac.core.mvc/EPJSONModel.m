//
//  EPJSONModel.m
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPJSONModel.h"

@implementation EPJSONModel

- (id)init {
    self = [super initWithPathSeparator:@"."];
    if (self) {
        data = [[EPJSONData alloc] init];
    }
    return self;
}

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [self init];
    if (self) {
        [self setRootWithConfiguration:config];
    }
    return self;
}

- (id)initWithData:(NSDictionary *)_data {
    self = [self init];
    if (self) {
        [self setRootWithData:_data];
    }
    return self;
}

- (id)getValueForPath:(NSString *)path {
    return [data getValueAtPath:path];
}

- (void)setValue:(id)value forPath:(NSString *)path {
    if (path) {
        [data setValue:value atPath:path];
        [self notifyDataObserversForPath:path];
    }
}

- (void)removeValueAtPath:(NSString *)path {
    if (path) {
        [data removeValueAtPath:path];
        [self notifyDataObserversForPath:path];
    }
}

- (void)setRootWithData:(NSDictionary *)_data {
    data = [[EPJSONData alloc] initWithData:_data];
    [self notifyAllDataObservers];
}

- (void)setRootWithConfiguration:(EPConfiguration *)configuration {
    data = [[EPJSONData alloc] initWithData:configuration.data];
    [self notifyAllDataObservers];
}

@end
