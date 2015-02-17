//
//  UIViewController+EP.h
//  EPCore
//
//  Created by Julian Goacher on 03/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPConfiguration.h"
#import "EPEventHandler.h"
#import "IFResourceObserver.h"

@protocol EPNavigationDelegate <NSObject>

- (void)openView:(UIViewController *)view;

@end

@interface EPViewControllerExtensions : NSObject

@property (nonatomic, strong) id<EPNavigationDelegate> navigationDelegate;
/*
@property (nonatomic, strong) NSArray *actionItems;

- (void)addActionItems:(NSArray *)items;
- (void)mergeExtensionsFrom:(EPViewControllerExtensions *)extensions;
*/
@end

@interface UIViewController (EP) <EPEventHandler, IFResourceObserver>

@property (nonatomic, strong) IFResource *contentResource;
@property (nonatomic, strong) EPViewControllerExtensions *extensions;

// Return a dictionary of the view's sub-components, keyed by name.
// This category returns an empty dictionary; UIViewController subclasses should override the method
// to return an actual dictionary of components.
- (NSDictionary *)componentsByName;

// Apply standard view controller configuration properties.
- (void)applyStandardConfiguration:(EPConfiguration *)configuration;

// Apply standard view controller on load configuration properties.
- (void)applyStandardOnLoadConfiguration:(EPConfiguration *)configuration;

// Apply standard view controller on appear configuration properties.
- (void)applyStandardOnAppearConfiguration:(EPConfiguration *)configuration;

// Load the view's content from a resource.
- (void)loadContentFromResource:(IFResource *)resource;

// Show a toast notification message.
- (void)showToast:(NSString *)message;

@end
