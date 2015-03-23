//
//  EPEventSource.h
//  EPCore
//
//  Created by Julian Goacher on 07/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPEventHandler.h"

@protocol EPEventSource <NSObject>

@property (nonatomic, strong) id<EPEventHandler> eventHandler;

@end
