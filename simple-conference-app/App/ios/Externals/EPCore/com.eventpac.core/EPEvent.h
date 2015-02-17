//
//  EPEvent.h
//  EPCore
//
//  Created by Julian Goacher on 23/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFResource.h"

@interface EPEvent : IFResource

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *action;
@property (nonatomic, strong) NSDictionary *arguments;

- (UIViewController *)resolveViewArgument;
- (EPEvent *)copyWithName:(NSString *)name;

+ (id)notHandledResult;
+ (BOOL)isNotHandled:(id)result;

@end
