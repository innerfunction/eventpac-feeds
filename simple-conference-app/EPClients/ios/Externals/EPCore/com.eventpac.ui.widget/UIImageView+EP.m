//
//  UIImageView+EP.m
//  EPCore
//
//  Created by Julian Goacher on 12/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "UIImageView+EP.h"
#import "UIImage+CropScale.h"
#import <objc/message.h>

@implementation UIImageView (EP)

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
    
    self.image = [config getValueAsImage:@"image"];
    NSString *action = [config getValueAsString:@"action"];
    
    self.tapHandler = [[EPTapHandler alloc] initWithAction:action eventHandler:eventHandler];
    [self.tapHandler attachToView:self];
    
    if ([config hasValue:@"observes"]) {
        self.observes = [config getValueAsString:@"observes"];
        EPCore *core = [EPCore getCore];
        EPDataModel *globalModel = core.mvc.globalModel;
        [globalModel addDataObserver:self forPath:self.observes];
    }
}

- (void)notifyDataChangedAtPath:(NSString *)path inModel:(EPModel *)model {
    // NOTE: Need to verify that the path here will be the path being observed, not a sub-path.
    EPCore *core = [EPCore getCore];
    EPDataModel *globalModel = core.mvc.globalModel;
    id value = [globalModel getValueForPath:self.observes];
    if ([value isKindOfClass:[NSString class]]) {
        UIImage *imageValue = [core resolveImage:(NSString *)value];
        if (imageValue) {
            self.image = imageValue;
        }
    }
    else if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *values = (NSDictionary *)value;
        NSString *image = (NSString *)[values objectForKey:@"image"];
        if (image) {
            UIImage *imageValue = [core resolveImage:image];
            if (imageValue) {
                /*
                CGSize size = self.frame.size;
                self.image = [[imageValue scaleToWidth:size.width] cropToHeight:size.height];
                */
                self.image = imageValue;
            }
        }
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
    }
}

@end
