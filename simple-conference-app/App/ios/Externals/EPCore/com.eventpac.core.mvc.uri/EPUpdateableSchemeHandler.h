//
//  EPUpdateableSchemeHandler.h
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPResourceModel.h"
#import "EPController.h"

@protocol EPUpdateableSchemeHandler <NSObject>

- (EPResourceModel *)getResourceModel:(EPController *)controller;

@end
