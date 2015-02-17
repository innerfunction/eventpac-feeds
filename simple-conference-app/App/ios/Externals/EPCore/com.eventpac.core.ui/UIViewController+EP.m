//
//  UIViewController+EP.m
//  EPCore
//
//  Created by Julian Goacher on 03/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "UIViewController+EP.h"
#import "EPCore.h"
#import "EPBarButtonItem.h"
#import "EPTabBarController.h"
#import "EPNavigationDrawerViewController.h"
#import "EPViewResource.h"
#import "EPBarButtonItem.h"
#import "UIView+Toast.h"
#import "IFCore.h"
#import <objc/message.h>

static const int ddLogLevel = IFCoreLogLevel;

@implementation EPViewControllerExtensions

- (id)init {
    self = [super init];
    if (self) {
        //self.actionItems = [NSArray array];
    }
    return self;
}

/*
- (void)addActionItems:(NSArray *)items {
    if (items && [items count] > 0) {
        if (_actionItems) {
            self.actionItems = [_actionItems arrayByAddingObjectsFromArray:items];
        }
        else {
            self.actionItems = items;
        }
    }
}

- (void)mergeExtensionsFrom:(EPViewControllerExtensions *)extensions {
    [self addActionItems:extensions.actionItems];
}
*/
@end

@implementation UIViewController (EP)

@dynamic contentResource;

// See http://stackoverflow.com/a/16708352 for description of this dynamic property technique.
- (void)setContentResource:(IFResource *)contentResource {
    IFResource *currentContentResource = self.contentResource;
    if (![currentContentResource isEqual:contentResource]) {
        EPController *mvc = [EPCore getCore].mvc;
        if (currentContentResource) {
            [mvc removeResourceObserver:self forResource:currentContentResource];
        }
        objc_setAssociatedObject(self, @selector(contentResource), contentResource, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [mvc addResourceObserver:self forResource:contentResource];
    }
}

- (IFResource *)contentResource {
    return objc_getAssociatedObject(self, @selector(contentResource));
}

// --
@dynamic extensions;

- (void)setExtensions:(EPViewControllerExtensions *)extensions {
    objc_setAssociatedObject(self, @selector(extensions), extensions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (EPViewControllerExtensions *)extensions {
    EPViewControllerExtensions *exts = objc_getAssociatedObject(self, @selector(extensions));
    if (!exts) {
        exts = [[EPViewControllerExtensions alloc] init];
        self.extensions = exts;
    }
    return exts;
}
// --

- (NSDictionary *)componentsByName {
    return [NSDictionary dictionary];
}

- (void)applyStandardConfiguration:(EPConfiguration *)configuration {
    /*
    if ([configuration hasValue:@"actionItem"]) {
        [self.extensions addActionItems:[NSArray arrayWithObject:[configuration getValueAsConfiguration:@"actionItem"]]];
    }
    if ([configuration hasValue:@"actionItems"]) {
        [self.extensions addActionItems:[configuration getValueAsConfigurationList:@"actionItems"]];
    }
    */
}

- (void)applyStandardOnLoadConfiguration:(EPConfiguration *)configuration {
    self.navigationController.navigationBarHidden = [configuration getValueAsBoolean:@"hideTitleBar" defaultValue:NO];
    NSString* title = [configuration getValueAsLocalizedString:@"title"];
    if (title && [title length]) {
        self.navigationItem.title = title;
    }
    else {
        self.navigationItem.title = self.title;
    }
    
    if ([configuration hasValue:@"titleBarColor"]) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        if (IsIOS7) {
            self.navigationController.navigationBar.barTintColor = [configuration getValueAsColor:@"titleBarColor"];
        }
        else {
            self.navigationController.navigationBar.tintColor = [configuration getValueAsColor:@"titleBarColor"];
        }
    }
    
    if ([configuration hasValue:@"titleBarTextColor"]) {
        if (IsIOS7) {
            self.navigationController.navigationBar.tintColor = [configuration getValueAsColor:@"titleBarTextColor"];
        }
        // TODO: Is anything necessary pre-iOS 7?
    }

    NSString *backButtonTitle = [configuration getValueAsString:@"backButtonTitle"];
    if (backButtonTitle) {
        backButtonTitle = NSLocalizedString(backButtonTitle, @"");
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:backButtonTitle style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    
    // Title bar action item.
    EPConfiguration *actionItemConfig = [configuration getValueAsConfiguration:@"actionItem"];
    if (actionItemConfig) {
        EPBarButtonItem *buttonItem = [[EPBarButtonItem alloc] initWithConfiguration:actionItemConfig];
        buttonItem.eventHandler = self;
        self.navigationItem.rightBarButtonItem = buttonItem;
    }
}

- (void)applyStandardOnAppearConfiguration:(EPConfiguration *)configuration {
    self.navigationController.navigationBarHidden = [configuration getValueAsBoolean:@"hideTitleBar" defaultValue:NO];

    // If this view controller has a parent view controller then add this class's right bar button item to the parent.
    // NOTE: This can result in an existing item being overwritten.
    if (self.parentViewController && self.navigationItem.rightBarButtonItem) {
        self.parentViewController.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
    }
    
    // Set the EPCore's active view to the current view.
    // TODO: There is a problem here with detecting the top-most view controller which is an EPView when nested view
    // controllers are displayed. The following code attempts to detect the case where the active view controller has
    // already been set the current view's parent view controller, but this may not work reliably in all cases.
    EPCore *core = [EPCore getCore];
    if (self.parentViewController != core.activeView) {
        core.activeView = self;
    }
}

- (void)loadContentFromResource:(id)resource {
    self.contentResource = resource;
}

#pragma mark - IFResourceObserver

- (void)resourceUpdated:(NSString *)name {
    [self loadContentFromResource:[self.contentResource refresh]];
}

#pragma mark - EPEventHandler

- (id)handleEPEvent:(EPEvent *)event {
    id result = [EPEvent notHandledResult];
    if ([event.name hasPrefix:@"nav/"]) {
        NSString *navAction = [event.name substringFromIndex:4];
        if ([@"open" isEqualToString:navAction]) {
            UIViewController *nextView = [event resolveViewArgument];
            EPNavigationDrawerViewController *parentNavDrawer = nil;
            // If the next view is a navigation drawer, and the current parent or grandparent is a navigation drawer, then
            // chain the two together. This allows a nested slide menu on the left hand side.
            if ([nextView isKindOfClass:[EPNavigationDrawerViewController class]]) {
                UIViewController *parent = self.parentViewController;
                while (parent) {
                    if ([parent isKindOfClass:[EPNavigationDrawerViewController class]]) {
                        parentNavDrawer = (EPNavigationDrawerViewController *)parent;
                        break;
                    }
                    parent = parent.parentViewController;
                }

                ((EPNavigationDrawerViewController *)nextView).parentNavigationDrawer = parentNavDrawer;
                [parentNavDrawer hideMenu];
            }
            
            id<EPNavigationDelegate> navigationDelegate = nil;
            UIViewController *view = self;
            while (!navigationDelegate && view) {
                navigationDelegate = view.extensions.navigationDelegate;
                view = view.parentViewController;
            }
            if (navigationDelegate) {
                [navigationDelegate openView:nextView];
                result = nil;
            }
            else if (self.navigationController) {
                [self.navigationController pushViewController:nextView animated:YES];
                result = nil;
            }
            else {
                DDLogWarn(@"UIViewController+EP: No navigation controller, nav/open can't open view");
            }
        }
        else if ([@"switch" isEqualToString:navAction]) {
            if (self.navigationController) {
                UIViewController *nextView = [event resolveViewArgument];
                if ([self.navigationController.viewControllers count] > 1) {
                    [self.navigationController popViewControllerAnimated:NO];
                    [self.navigationController pushViewController:nextView animated:YES];
                    result = nil;
                }
                else {
                    // If the view being replaced is the navigation controller's root view then we can't pop it, so have
                    // to replace the list of view controllers instead.
                    [self.navigationController setViewControllers:@[ nextView ] animated:YES];
                }
            }
            else {
                DDLogWarn(@"UIViewController+EP: No navigation controller, nav/switch can't open view");
            }
        }
        else if ([@"back" isEqualToString:navAction]) {
            if (self.navigationController) {
                [self.navigationController popViewControllerAnimated:YES];
                result = nil;
            }
            else {
                DDLogWarn(@"UIViewController+EP: No navigation controller, nav/back can't close view");
            }
        }
        else if ([@"tab" isEqualToString:navAction]) {
            if ([self.tabBarController isKindOfClass:[EPTabBarController class]]) {
                [(EPTabBarController *)self.tabBarController switchToTabWithID:event.uri.fragment];
                result = nil;
            }
            // TODO: May be better ways to encapsulate this logic...
            else if ([self isKindOfClass:[EPNavigationDrawerViewController class]]) {
                [(EPNavigationDrawerViewController *)self switchToTabWithID:event.uri.fragment];
                result = nil;
            }
            else {
                DDLogWarn(@"UIViewController+EP: No tabbar controller, nav/tab can't open view");
            }
        }
    }
    else if ([event.name hasPrefix:@"component/"]) {
        // If the event name is in the form 'component/<name>' then try routing the event to a view component with that name.
        NSString *componentRef = [event.name substringFromIndex:10];
        NSUInteger idx = [componentRef rangeOfString:@"."].location;
        if (idx != NSNotFound) {
            NSString *componentName = [componentRef substringWithRange:NSMakeRange(0, idx)];
            id<EPComponent> component = [self.componentsByName objectForKey:componentName];
            if ([component conformsToProtocol:@protocol(EPEventHandler)]) {
                NSString *actionName = [componentRef substringFromIndex:idx];
                result = [(id<EPEventHandler>)component handleEPEvent:[event copyWithName:actionName]];
            }
        }
    }
    else if ([event.name isEqualToString:@"notify/updating"]) {
        // TODO: Maybe show a blocking spinner in the UI.
    }
    else if ([event.name isEqualToString:@"notify/not-updating"]) {
        // TODO: Clear any message currently showing in the UI.
    }
    // If this controller has a parent view controller, and it implements the EPEventHandler protocol, then
    // pass the event up to it
    if ([EPEvent isNotHandled:result] && [self.parentViewController conformsToProtocol:@protocol(EPEventHandler)]) {
        result = [((id<EPEventHandler>)self.parentViewController) handleEPEvent:event];
    }
    // Otherwise pass the event to EPCore
    if ([EPEvent isNotHandled:result]) {
        result = [[EPCore getCore] handleEPEvent:event];
    }
    return [EPEvent isNotHandled:result] ? nil : result;
}

- (void)showToast:(NSString *)message {
    message = NSLocalizedString(message, @"");
    [self.view hideToastActivity]; // Hide any currently visible toast message.
    [self.view makeToast:message duration:ToastMessageDuration position:CSToastPositionBottom];
}

@end
