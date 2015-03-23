//
//  UILabel+EP.m
//  EPCore
//
//  Created by Julian Goacher on 12/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "UILabel+EP.h"
#import "EPCore.h"
#import <objc/message.h>

@implementation UILabel (EP)

@dynamic observes;

// See http://stackoverflow.com/a/16708352 for description of this dynamic property technique.
- (void)setObserves:(NSString *)observes {
    return objc_setAssociatedObject(self, @selector(observes), observes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)observes {
    return objc_getAssociatedObject(self, @selector(observes));
}

- (void)configureWithConfiguration:(EPConfiguration *)config eventHandler:(id<EPEventHandler>)eventHandler {
    [super configureWithConfiguration:config eventHandler:eventHandler];
    self.text = [config getValueAsString:@"text"];
    if ([config hasValue:@"backgroundColor"]) {
        self.backgroundColor = [config getValueAsColor:@"backgroundColor"];
    }
    if ([config hasValue:@"color"]) {
        self.textColor = [config getValueAsColor:@"color"];
    }
    if ([config hasValue:@"font"]) {
        NSString *fontName = [config getValueAsString:@"font.name" defaultValue:@"HelveticaNeue"];
        NSNumber *fontSize = [config getValueAsNumber:@"font.size" defaultValue:[NSNumber numberWithInteger:12]];
        self.font = [UIFont fontWithName:fontName size:[fontSize floatValue]];
    }
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
    self.text = [value description];
}

- (void)destroyDataObserver {}

- (void)willRemoveSubview:(UIView *)subview {
    [super willRemoveSubview:subview];
    [[EPCore getCore].mvc.globalModel removeDataObserver:self];
}

@end
