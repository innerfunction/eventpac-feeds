//
//  UIView+EP.m
//  EPCore
//
//  Created by Julian Goacher on 12/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "UIView+EP.h"
#import "NSDictionary+IF.h"
#import "IFCore.h"
#import "EPCore.h"
#import "EPEventSource.h"
#import "UIViewController+EP.h"

#define LogTag @"UIView(EP):"

static const int ddLogLevel = IFCoreLogLevel;

@implementation UIView (EP)

- (BOOL)layoutWithConfiguration:(EPConfiguration *)configuration owner:(id)owner {
    BOOL result = NO;
    if ([configuration hasValue:@"layout"]) {
        NSString *nibName = [configuration getValueAsString:@"layout"];
        DDLogInfo(@"%@ Loading view nib from %@...", LogTag, nibName);
        [[NSBundle mainBundle] loadNibNamed:nibName owner:owner options:nil];
        result = YES;
    }
    return result;
}

- (void)configureWithConfiguration:(EPConfiguration *)config eventHandler:(id<EPEventHandler>)eventHandler {
}

- (NSDictionary *)layoutSubviewsUsingConfiguration:(EPConfiguration *)config {
    return [self layoutSubviewsUsingConfiguration:config container:nil];
}

- (NSDictionary *)layoutSubviewsUsingConfiguration:(EPConfiguration *)config container:(UIViewController *)container {
    // A dictionary of all named components contained by this view.
    NSDictionary *namedSubviews = [NSDictionary dictionary];
    // A map of component configurations keyed by component name.
    NSDictionary *componentConfigs = [config getValueAsConfigurationMap:@"components"];
    // Check if we have an event handler.
    id<EPEventHandler> eventHandler = nil;
    if ([container conformsToProtocol:@protocol(EPEventHandler)]) {
        eventHandler = (id<EPEventHandler>)container;
    }
    // Iterate over the named components.
    for (NSString *name in componentConfigs) {
        EPConfiguration *componentConfig = [[componentConfigs objectForKey:name] flatten];
        // Look for a subview tag in the configuration.
        NSInteger tag = [componentConfig getValueAsNumber:@"ios:tag"].integerValue;
        if (tag) {
            // Look for a subview with the component tag.
            UIView *subview = [self viewWithTag:tag];
            if (subview) {
                id component = nil;
                // Subview found. First attempt creating a component with the configuration.
                // (This will only work if the config has a "type" property, or a "config" property
                // which might contain a type);
                if ([componentConfig hasValue:@"type"] || [componentConfig hasValue:@"config"]) {
                    // Attempt component creation and then replace the subview with the new component.
                    component = [self replaceSubview:subview withComponentConfiguration:componentConfig container:container];
                    if (component) {
                        if ([component conformsToProtocol:@protocol(EPEventSource)]) {
                            ((id<EPEventSource>)component).eventHandler = eventHandler;
                        }
                        namedSubviews = [namedSubviews dictionaryWithAddedObject:component forKey:name];
                    }
                }
                // If couldn't create a component, then attempt configuring it via the EPConfigurableWidget
                // protocol.
                if (!component && [subview conformsToProtocol:@protocol(EPConfigurableWidget)]) {
                    [(id<EPConfigurableWidget>)subview configureWithConfiguration:componentConfig eventHandler:eventHandler];
                    namedSubviews = [namedSubviews dictionaryWithAddedObject:subview forKey:name];
                }
            }
            else {
                DDLogWarn(@"%@: View with tag %ld not found for component named %@", LogTag, (long)tag, name );
            }
        }
        else {
            DDLogWarn(@"%@: View tag not defined for component named %@", LogTag, name );
        }
    }
    return namedSubviews;
}

- (id)replaceSubview:(UIView *)subview withComponentConfiguration:(EPConfiguration *)config container:(UIViewController *)container; {
    NSString *type = [config getValueAsString:@"type"];
    // If the subview config has a type then construct it as an EP component.
    NSString *cid = [NSString stringWithFormat:@"Layout view type: %@", type];
    EPCore *core = [EPCore getCore];
    id component = [core makeComponentWithConfiguration:config identifier:cid];
    if ([component isKindOfClass:[UIView class]]) {
        [self replaceSubview:subview withView:(UIView *)component];
    }
    else if ([component isKindOfClass:[UIViewController class]]) {
        if (container) {
            // If the view is an instance of UIViewController then add it to the view heirarchy.
            // TODO: There are some questions about this:
            //  * It seems to be the case that the view controller's view has to be added separately (as done here);
            //    addChildViewController: only ensures that lifecycle methods are forwarded from this controller to the child.
            //  * But will viewController.view resolve correctly at this point for all views?
            //  * Also, note that this current implementation allows the layout to populate components into the child view
            //    controller's view... this may or may not be useful.
            UIViewController *viewController = (UIViewController *)component;
            [container addChildViewController:viewController];
            // Merge extensions e.g. action items - into the parent.
            //[container.extensions mergeExtensionsFrom:viewController.extensions];
            if (!container.navigationItem.rightBarButtonItem) {
                container.navigationItem.rightBarButtonItem = viewController.navigationItem.rightBarButtonItem;
            }
            //[self addSubview:viewController.view];
            [self replaceSubview:subview withView:viewController.view];
        }
        else {
            DDLogWarn(@"%@ Can't add view controller subview to layout, container UIViewController not available", LogTag );
        }
    }
    else if (component) {
        DDLogWarn(@"%@ Layout view type %@ is not an instance of UIView or UIViewController", LogTag, type );
    }
    return component;
}

- (void)replaceSubview:(UIView *)subview withView:(UIView *)newview {
    // Copy frame and bounds
    newview.frame = subview.frame;
    newview.bounds = subview.bounds;
    //NSLog(@"%f %f %f %f", newview.frame.origin.x,newview.frame.origin.y,newview.frame.size.width,newview.frame.size.height);
    // Copy layout params to the new view
    newview.autoresizingMask = subview.autoresizingMask;
    newview.autoresizesSubviews = subview.autoresizesSubviews;
    newview.contentMode = subview.contentMode;
    // Swap the views.
    UIView *superview = subview.superview;
    NSUInteger idx = [superview.subviews indexOfObject:subview];
    [subview removeFromSuperview];
    [superview insertSubview:newview atIndex:idx];
}

@end
