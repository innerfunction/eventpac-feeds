//
//  EPConfigurableWidget.h
//  EPCore
//
//  Created by Julian Goacher on 12/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPConfiguration.h"
#import "EPEventHandler.h"

@protocol EPConfigurableWidget <NSObject>

- (void)configureWithConfiguration:(EPConfiguration *)config eventHandler:(id<EPEventHandler>)eventHandler;

@end
