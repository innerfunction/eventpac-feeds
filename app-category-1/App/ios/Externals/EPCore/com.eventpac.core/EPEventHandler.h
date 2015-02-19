//
//  EPEventHandler.h
//  EPCore
//
//  Created by Julian Goacher on 22/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPEvent.h"

@protocol EPEventHandler <NSObject>

- (id)handleEPEvent:(EPEvent *)event;

@end