//
//  EPFormatter.h
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EPFormatter <NSObject>

- (NSString *)formatValue:(id)value;

- (id)parseValue:(NSString *)value;

@end
