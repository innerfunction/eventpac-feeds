//
//  UIView+EP.h
//  EPCore
//
//  Created by Julian Goacher on 12/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPComponent.h"
#import "EPConfigurableWidget.h"

@interface UIView (EP) <EPConfigurableWidget>

- (BOOL)layoutWithConfiguration:(EPConfiguration *)configuration owner:(id)owner;
- (NSDictionary *)layoutSubviewsUsingConfiguration:(EPConfiguration *)config;
- (NSDictionary *)layoutSubviewsUsingConfiguration:(EPConfiguration *)config container:(UIViewController *)container;
- (id)replaceSubview:(UIView *)subview withComponentConfiguration:(EPConfiguration *)config container:(UIViewController *)container;
- (void)replaceSubview:(UIView *)subview withView:(UIView *)newview;

@end
