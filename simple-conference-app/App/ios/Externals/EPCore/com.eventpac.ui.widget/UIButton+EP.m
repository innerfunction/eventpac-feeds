//
//  UIButton+EP.m
//  EPCore
//
//  Created by Julian Goacher on 12/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "UIButton+EP.h"
#import <objc/message.h>

// TODO: Anyway to access named sub-components and attach event driven behaviour?

@implementation UIButton (EP)

@dynamic tapHandler, observes;

// See http://stackoverflow.com/a/16708352 for description of this dynamic property technique.
- (void)setTapHandler:(EPTapHandler *)tapHandler {
    return objc_setAssociatedObject(self, @selector(tapHandler), tapHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (EPTapHandler *)tapHandler {
    return objc_getAssociatedObject(self, @selector(tapHandler));
}

- (void)setObserves:(NSString *)observes {
    return objc_setAssociatedObject(self, @selector(observes), observes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)observes {
    return objc_getAssociatedObject(self, @selector(observes));
}

- (void)configureWithConfiguration:(EPConfiguration *)config eventHandler:(id<EPEventHandler>)eventHandler {
    [super configureWithConfiguration:config eventHandler:eventHandler];
    
    NSString *action = [config getValueAsString:@"action"];
    
    self.tapHandler = [[EPTapHandler alloc] initWithAction:action eventHandler:eventHandler];
    [self.tapHandler attachToView:self];

    [self configureWithConfiguration:config forControlState:UIControlStateNormal];
    // TODO: [self adjustsImageWhenHighlighted:YES];
    
    [self configureWithConfiguration:config forControlState:UIControlStateNormal];
    if ([config hasValue:@"states.normal"]) {
        [self configureWithConfiguration:[config getValueAsConfiguration:@"states.normal"] forControlState:UIControlStateNormal];
    }
    if ([config hasValue:@"states.pressed"]) {
        [self configureWithConfiguration:[config getValueAsConfiguration:@"states.pressed"] forControlState:UIControlStateHighlighted];
        //[self configureWithConfiguration:[config getValueAsConfiguration:@"states.pressed"] forControlState:UIControlStateSelected];
    }
    [[EPCore getCore] addDataObserver:self forConfiguration:config];
}

- (void)notifyDataChangedAtPath:(NSString *)path inModel:(EPModel *)model {
    // NOTE: Need to verify that the path here will be the path being observed, not a sub-path.
    EPCore *core = [EPCore getCore];
    EPDataModel *globalModel = core.mvc.globalModel;
    id value = [globalModel getValueForPath:self.observes];
    if ([value isKindOfClass:[NSString class]]) {
        [self setImage:[core resolveImage:(NSString *)value] forState:UIControlStateNormal];
    }
    else if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *values = (NSDictionary *)value;
        NSString *action = (NSString *)[values objectForKey:@"action"];
        if (action) {
            self.tapHandler.action = action;
        }
    }
}

- (void)destroyDataObserver {}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (!newSuperview) {
        [[EPCore getCore].mvc.globalModel removeDataObserver:self];
        self.tapHandler = nil;
    }
}

- (void)configureWithConfiguration:(EPConfiguration *)config forControlState:(UIControlState)state {
    if ([config hasValue:@"backgroundImage"]) {
        [self setBackgroundImage:[config getValueAsImage:@"backgroundImage"] forState:state];
    }
    if ([config hasValue:@"backgroundColor"]) {
        self.backgroundColor = [config getValueAsColor:@"backgroundColor"];
    }
}

@end
