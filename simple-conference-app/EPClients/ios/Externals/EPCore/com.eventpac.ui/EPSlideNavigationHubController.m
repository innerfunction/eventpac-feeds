//
//  EPSlideNavigationHubController.m
//  EPCore
//
//  Created by Julian Goacher on 18/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPSlideNavigationHubController.h"
#import "EPCore.h"

#define TogglePrevAction @"slidenav/toggle-prev"

@interface EPSlideNavigationHubController ()

- (void)addControls:(UIViewController *)view;
- (void)observeNavigationItem:(UINavigationItem *)navItem;
- (void)removeNavigationItemObserver;

@end

@implementation EPSlideNavigationHubController

@synthesize core, viewURI;

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super initWithRearViewController:nil frontViewController:nil];
    if (self) {
        configuration = config;
        EPConfiguration *buttonConfig = [configuration getValueAsConfiguration:@"backButton"];
        if (buttonConfig) {
            backButton = [[EPBarButtonItem alloc] initWithConfiguration:buttonConfig];
            backButton.eventAction = TogglePrevAction;
            backButton.eventHandler = self;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyStandardOnLoadConfiguration:configuration];
    EPConfiguration *viewConfig = [configuration getValueAsConfiguration:@"mainView"];
    UIViewController *view = (UIViewController *)[self.core makeComponentWithConfiguration:viewConfig identifier:@"SlideNavigationHub.mainView"];
    view.extensions.navigationDelegate = self;
    self.rearViewController = view;
    [self setFrontViewPosition:FrontViewPositionRightMostRemoved];
    // Setup initial screen title.
    UINavigationItem *navItem = view.navigationItem;
    [self observeNavigationItem:navItem];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.frontViewPosition == FrontViewPositionRight) {
        // If returning to the view and the rear view is partially visible (because it has been re-opened from the
        // front view) then make fully visible by fully hiding the front view.
        [self setFrontViewPosition:FrontViewPositionRightMostRemoved animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self applyStandardOnAppearConfiguration:configuration];
    self.delegate = self;
    if (!navButton) {
        // Record the navigation back button in the top LHS title bar posisition.
        // NOTE: This is not necessarily a back button, can be e.g. a show menu button as added by a navigation drawer.
        navButton = self.navigationItem.leftBarButtonItem;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    self.delegate = nil;
}

- (void)openView:(UIViewController *)view {
    [self addControls:view];
    [self setFrontViewController:view animated:YES];
    [self setFrontViewPosition:FrontViewPositionLeftSideMost animated:YES];
    // TODO: Check for tabs on the view, add to RHS slide view.
}

// Add title bar buttons and swipe controls to a tab view which is about to be made visible.
- (void)addControls:(UIViewController *)view {
    if (backButton) {
        UINavigationItem *navItem;
        if ([view isKindOfClass:[UINavigationController class]]) {
            UIViewController *top = [(UINavigationController *)view topViewController];
            navItem = top.navigationItem;
        }
        else {
            navItem = view.navigationItem;
        }
        
        if (navItem) {
            navItem.leftBarButtonItem = backButton;
        }
    }
    // Add swipe gestures.
    [view.view addGestureRecognizer:[self panGestureRecognizer]];
}

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position {
    [self removeNavigationItemObserver];
    switch (position) {
        case FrontViewPositionLeft:
            // 'prev' (menu) button + front view controller's action button (which could be the tab button)
            self.navigationItem.leftBarButtonItem = backButton;
            [self observeNavigationItem:revealController.frontViewController.navigationItem];
            break;
        case FrontViewPositionRight:
            // initial LHS button + rear view controller's action button
            self.navigationItem.leftBarButtonItem = navButton;
            [self observeNavigationItem:revealController.rearViewController.navigationItem];
            break;
            
        default:
            break;
    }
}

#define ObserveOptions (NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial)

- (void)observeNavigationItem:(UINavigationItem *)navItem {
    [navItem addObserver:self forKeyPath:@"title" options:ObserveOptions context:NULL];
    [navItem addObserver:self forKeyPath:@"rightBarButtonItem" options:ObserveOptions context:NULL];
    observedItem = navItem;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"title" isEqualToString:keyPath]) {
        self.navigationItem.title = ((UINavigationItem *)object).title;
    }
    else if ([@"rightBarButtonItem" isEqualToString:keyPath]) {
        self.navigationItem.rightBarButtonItem = ((UINavigationItem *)object).rightBarButtonItem;
    }
}

- (void)removeNavigationItemObserver {
    if (observedItem) {
        [observedItem removeObserver:self forKeyPath:@"title"];
        [observedItem removeObserver:self forKeyPath:@"rightBarButtonItem"];
        observedItem = nil;
    }
}

- (id)handleEPEvent:(EPEvent *)event {
    id result = [EPEvent notHandledResult];
    if ([event.name isEqualToString:TogglePrevAction]) {
        [self revealToggleAnimated:YES];
        result = nil;
    }
    return result;
}

@end
