//
//  EPFlurryService.h
//  EventPacComponents
//
//  Created by Julian Goacher on 26/11/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPService.h"

@interface EPFlurryService : NSObject <EPService> {
    NSString *appKey;
}

@end
