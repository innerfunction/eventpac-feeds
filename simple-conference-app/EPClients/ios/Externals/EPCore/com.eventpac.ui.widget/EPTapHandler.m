//
//  EPTapHandler.m
//  EPCore
//
//  Created by Julian Goacher on 12/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPTapHandler.h"

@implementation EPTapHandler

- (id)initWithAction:(NSString *)action eventHandler:(id<EPEventHandler>)_eventHandler {
    self = [super init];
    if (self) {
        core = [EPCore getCore];
        self.action = action;
        eventHandler = _eventHandler;
    }
    return self;
}

- (void)attachToView:(UIView *)view {
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [view addGestureRecognizer:recognizer];
    view.userInteractionEnabled = YES;
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    // CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    if (self.action) {
        [core dispatchAction:self.action toHandler:eventHandler];
    }
}

@end
