//
//  EPDBHelper.h
//  EPCore
//
//  Created by Julian Goacher on 24/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPConfiguration.h"
#import "EPComponent.h"
#import "IFDBHelper.h"

@class EPDBController;

@interface EPDBHelper : IFDBHelper <IFDBHelperDelegate, EPComponent> {
    EPConfiguration *configuration;
    NSMutableDictionary *initialData;
}

@property (nonatomic, strong) EPDBController *controller;

@end
