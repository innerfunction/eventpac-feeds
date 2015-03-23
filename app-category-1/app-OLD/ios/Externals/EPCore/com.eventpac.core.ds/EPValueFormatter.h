//
//  EPValueFormatter.h
//  EPCore
//
//  Created by Julian Goacher on 23/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EPValueFormatter : NSObject

- (id)format:(id)value;

+ (EPValueFormatter *)forType:(NSString *)type;

@end
