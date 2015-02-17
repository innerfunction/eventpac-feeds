//
//  EPGoogleMapService.h
//  EPCore
//
//  Created by Julian Goacher on 06/01/2015.
//  Copyright (c) 2015 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPService.h"

@interface EPGoogleMapService : NSObject <EPService> {
    NSString *apiKey;
}

@end
