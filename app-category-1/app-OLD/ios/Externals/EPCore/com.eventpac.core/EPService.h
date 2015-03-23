//
//  EPService.h
//  EPCore
//
//  Created by Julian Goacher on 10/02/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPComponent.h"

@protocol EPService <EPComponent>

- (void)startService;
- (void)stopService;

@end
