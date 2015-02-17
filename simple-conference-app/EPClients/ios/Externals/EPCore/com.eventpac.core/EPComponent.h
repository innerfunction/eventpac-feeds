//
//  EPComponent.h
//  EPCore
//
//  Created by Julian Goacher on 10/02/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPConfiguration.h"

@class EPCore;

@protocol EPComponentFactory <NSObject>

+ (id)componentWithConfiguration:(EPConfiguration *)config;

@end

@protocol EPComponent <NSObject>

- (id)initWithConfiguration:(EPConfiguration *)config;

@optional

@property (nonatomic, strong) EPCore *core;

@end
