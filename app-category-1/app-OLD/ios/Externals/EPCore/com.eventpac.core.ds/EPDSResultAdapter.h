//
//  EPDSResultAdapter.h
//  EPCore
//
//  Created by Julian Goacher on 28/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPComponent.h"

@protocol EPDSResultAdapter <EPComponent>

- (id)mapResult:(NSArray *)result;

@end
