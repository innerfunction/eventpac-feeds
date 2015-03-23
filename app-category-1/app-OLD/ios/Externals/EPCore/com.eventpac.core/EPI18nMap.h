//
//  EPI18nMap.h
//  EPCore
//
//  Created by Julian Goacher on 23/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EPI18nMap : NSObject

- (id)valueForKey:(NSString *)key;

+ (EPI18nMap *)instance;

@end
