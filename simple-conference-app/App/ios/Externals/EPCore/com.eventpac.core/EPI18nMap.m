//
//  EPI18nMap.m
//  EPCore
//
//  Created by Julian Goacher on 23/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPI18nMap.h"

@implementation EPI18nMap

- (id)valueForKey:(NSString *)key {
    NSString *s = NSLocalizedString(key, @"");
    return s ? s : key;
}

static EPI18nMap *instance;

+ (void)initialize {
    instance = [[EPI18nMap alloc] init];
}

+ (EPI18nMap *)instance {
    return instance;
}

@end
