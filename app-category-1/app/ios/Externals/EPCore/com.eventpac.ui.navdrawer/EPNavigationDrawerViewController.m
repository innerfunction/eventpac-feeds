//
//  EPTabSlideViewController.m
//  EventPacComponents
//
//  Created by Julian Goacher on 29/10/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "EPNavigationDrawerViewController.h"
#import "UIViewController+EP.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

@interface EPNavigationDrawerViewController ()

- (void)addControls:(UIViewController *)tabView;

@end

@implementation EPNavigationDrawerViewController

@synthesize viewURI;

- (id)initWithConfiguration:(EPConfiguration *)config {
    return [self initWithConfiguration:config defaultPosition:@"left"];
}

- (id)initWithConfiguration:(EPConfiguration *)config defaultPosition:(NSString *)defaultPosition {
    self.position = [@"left" isEqualToString:[config getValueAsString:@"ios:position" defaultValue:defaultPosition]] ? EPNavigationDrawerListPositionLeft : EPNavigationDrawerListPositionRight;
    EPConfiguration *tabListConfig = [config getValueAsConfiguration:@"tabList"];
    tabList = [[EPNavigationDrawerListViewController alloc] initWithConfiguration:tabListConfig];
    self.tabController = [[EPTabController alloc] initWithConfiguration:config];
    UIViewController *rearViewController = (self.position == EPNavigationDrawerListPositionLeft) ? tabList : nil;
    self = [super initWithRearViewController:rearViewController frontViewController:nil];
    if (self) {
        configuration = config;
        tabList.parent = self;
        
        if (self.position == EPNavigationDrawerListPositionRight) {
            self.rightViewController = tabList;
        }
        
        if (tabList.width) {
            if (self.position == EPNavigationDrawerListPositionLeft) {
                self.rearViewRevealWidth = tabList.width;
            }
            else {
                self.rightViewRevealWidth = tabList.width;
            }
        }
        
        EPConfiguration *menuButtonConfig = [config getValueAsConfiguration:@"ios:menuButton"];
        if (menuButtonConfig) {
            self.menuButton = [[EPBarButtonItem alloc] initWithConfiguration:menuButtonConfig];
            self.menuButton.eventAction = @"navdrawer/toggle-menu";
            self.menuButton.eventHandler = self;
        }
    }
    return self;
}

- (void)setTabController:(EPTabController *)tabController {
    _tabController = tabController;
    tabList.tabController = tabController;
}

- (void)viewDidLoad {
	// Do any additional setup after loading the view.
    [self.tabController viewDidLoad];
    tabList.tabs = self.tabController.tabs;
    self.tabs = self.tabController.tabs;
    if ([self.tabs count] > 0) {
        NSInteger selectedTabIdx = 0;
        NSString *openTab = [configuration getValueAsString:@"openTab"];
        if (openTab) {
            selectedTabIdx = [self.tabController indexOfTabWithID:openTab];
            if (selectedTabIdx > -1) {
                [self.tabController switchToTabWithID:openTab];
            }
            else {
                selectedTabIdx = 0;
            }
        }
        self.frontViewController = [self.tabs objectAtIndex:selectedTabIdx];
        [self addControls:self.frontViewController];

    }
    else {
        DDLogWarn(@"EPNavigationDrawerViewController: No tabs specified");
    }
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
}

- (BOOL)switchToTabWithID:(NSString *)tabID {
    UIViewController* tabView = [self.tabController switchToTabWithID:tabID];
    if (tabView) {
        [tabList selectTabWithID:tabID];
        [self addControls:tabView];
        // Show the tab in the front view; animate only when the tab menu is in the left position.
        if (self.position == EPNavigationDrawerListPositionLeft) {
            [self setFrontViewController:tabView animated:YES];
        }
        else {
            [self setFrontViewController:tabView animated:NO];
            [self toggleMenu];
        }
        currentTabID = tabID;
    }
    return !!tabView;
}

- (void)showMenu {
    if (self.position == EPNavigationDrawerListPositionLeft) {
        [self setFrontViewPosition:FrontViewPositionRightMost animated:YES];
    }
    else {
        [self setFrontViewPosition:FrontViewPositionLeftSideMost animated:YES];
    }
}

- (void)hideMenu {
    if (self.position == EPNavigationDrawerListPositionLeft) {
        [self setFrontViewPosition:FrontViewPositionLeftSideMostRemoved animated:YES];
    }
    else {
        [self setFrontViewPosition:FrontViewPositionRightMostRemoved animated:YES];
    }
}

- (void)toggleMenu {
    if (self.position == EPNavigationDrawerListPositionLeft) {
        [self revealToggleAnimated:YES];
    }
    else {
        [self rightRevealToggleAnimated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addControls:(UIViewController *)tabView {
    // NOTE: It seems to be safe to add the same gesture recognizer to the same view multiple times, ios
    // seems to detect and handle when the same recognizer was previously added.
    /*
    if (tabView.navigationController) {
        // TODO: Review the previous conditional - this code is never being called.
        UINavigationBar* navbar = tabView.navigationController.navigationBar;
        [navbar addGestureRecognizer:[self panGestureRecognizer]];
        // TODO: Add a button to the LHS nav bar item for displaying the tabs by tap.
    }
    */

    UINavigationItem *topNavItem = nil;
    if ([tabView isKindOfClass:[UINavigationController class]]) {
        UIViewController *top = [(UINavigationController *)tabView topViewController];
        topNavItem = top.navigationItem;
        [tabView.view addGestureRecognizer:[self panGestureRecognizer]];
    }
    else if (tabView.navigationItem) {
        topNavItem = tabView.navigationItem;
        [tabView.view addGestureRecognizer:[self panGestureRecognizer]];
    }
    else {
        [tabView.view addGestureRecognizer:[self panGestureRecognizer]];
    }
    if (topNavItem && self.menuButton) {
        // Add menu button, if position not already taken.
        if (self.position == EPNavigationDrawerListPositionLeft) {
            if (!topNavItem.leftBarButtonItem) {
                topNavItem.leftBarButtonItem = self.menuButton;
            }
        }
        else {
            if (!topNavItem.rightBarButtonItem) {
                topNavItem.rightBarButtonItem = self.menuButton;
            }
        }
    }
}

- (id)handleEPEvent:(EPEvent *)event {
    id result = [EPEvent notHandledResult];
    if ([event.name hasPrefix:@"navdrawer/"]) {
        NSString *action = [event.name substringFromIndex:[@"navdrawer/" length]];
        if ([@"toggle-menu" isEqualToString:action]) {
            [self toggleMenu];
            result = nil;
        }
        else if([@"toggle-left" isEqualToString:action]) {
            [self revealToggleAnimated:YES];
            result = nil;
        }
    }
    if ([EPEvent isNotHandled:result]) {
        result = [super handleEPEvent:event];
    }
    return result;
}

@end
