//
//  EPTapHandler.h
//  EPCore
//
//  Created by Julian Goacher on 12/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPCore.h"
#import "EPEventHandler.h"

@interface EPTapHandler : NSObject {
    EPCore *core;
    id<EPEventHandler> eventHandler;
}

@property (nonatomic, strong) NSString *action;

- (id)initWithAction:(NSString *)action eventHandler:(id<EPEventHandler>)eventHandler;
- (void)attachToView:(UIView *)view;
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer;

@end
