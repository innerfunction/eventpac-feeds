//
//  EPViewFactory.h
//  EPCore
//
//  Created by Julian Goacher on 03/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPService.h"
#import "EPView.h"

@interface EPViewFactoryService : NSObject <EPService> {
    EPConfiguration *definitions;
}

- (IFResource *)makeViewResourceForURI:(IFCompoundURI *)uri parameters:(NSDictionary *)params parent:(IFResource *)parent;
- (UIViewController *)makeViewForURI:(IFCompoundURI *)uri configuration:(EPConfiguration *)config;
- (EPConfiguration *)getViewConfigurationForURI:(IFCompoundURI *)uri parameters:(NSDictionary *)params;

@end
