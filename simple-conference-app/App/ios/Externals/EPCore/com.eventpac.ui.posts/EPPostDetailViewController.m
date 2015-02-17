//
//  EPPostDetailViewController.m
//  EPCore
//
//  Created by Julian Goacher on 10/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPPostDetailViewController.h"
#import "EPPostTableViewController.h"
#import "EPTableViewController.h"
#import "EPViewResource.h"
#import "UIViewController+EP.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

#define EPEventPrefix           @"postdetail/"
#define EPEventAction(name)     ([NSString stringWithFormat:@"%@%@", EPEventPrefix, name])

@interface EPPostDetailViewController ()

- (void)addControls:(UIViewController *)tabView;

@end

@implementation EPPostDetailViewController

@synthesize core, viewURI;

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super initWithRearViewController:nil frontViewController:nil];
    if (self) {
        
        configuration = config;

        // Configure tabs & tab list.
        NSArray *tabs = (NSArray *)[config getValue:@"tabs"];
        EPConfiguration *tabListConfig = [config getValueAsConfiguration:@"tabList"];
        // Use a tabs list if more than three tabs + we have a tab list config.
        if ([tabs count] > 3 && tabListConfig) {
            tabDisplayType = TabDisplayList;
            tabList = [[EPPostTabListViewController alloc] initWithConfiguration:tabListConfig];
            tabList.parent = self;
            self.rightViewController = tabList;
            if (tabList.width) {
                self.rightViewRevealWidth = tabList.width;
            }
            self.tabController = [[EPTabController alloc] initWithConfiguration:config];
        }
        else if ([tabs count] > 1) {
            tabDisplayType = TabDisplayBar;
            tabBar = [[EPTabBarController alloc] initWithConfiguration:config];
            tabBar.delegate = self;
            self.frontViewController = tabBar;
            self.tabController = tabBar.tabController;
        }
        else {
            tabDisplayType = TabDisplayNone;
            self.tabController = [[EPTabController alloc] initWithConfiguration:config];
        }
        
        // Add button for toggling display of posts list.
        EPConfiguration *buttonConfig = [configuration getValueAsConfiguration:@"postListButton"];
        if (buttonConfig) {
            postListButton = [[EPBarButtonItem alloc] initWithConfiguration:buttonConfig];
            postListButton.eventHandler = self;
            postListButton.eventAction = EPEventAction(@"toggle-post-list");
        }
        
        // Add button for toggling display of tabs list.
        if (tabDisplayType == TabDisplayList) {
            buttonConfig = [configuration getValueAsConfiguration:@"tabListButton"];
            if (buttonConfig) {
                tabListButton = [[EPBarButtonItem alloc] initWithConfiguration:buttonConfig];
                tabListButton.eventHandler = self;
                tabListButton.eventAction = EPEventAction(@"toggle-tab-list");
            }
        }
        
        // Add button for toggling post favourites status.
        buttonConfig = [configuration getValueAsConfiguration:@"favouriteButton"];
        if (buttonConfig) {
            favouriteButton = [[EPFavouriteBarButtonItem alloc] initWithConfiguration:buttonConfig];
        }
        
        self.postID = [configuration getValueAsString:@"postID"];
    }
    return self;
}

- (void)setTabController:(EPTabController *)tabController {
    _tabController = tabController;
    if (tabList) {
        tabList.tabController = tabController;
    }
}

- (void)setPostID:(NSString *)postID {
    _postID = postID;
    favouriteButton.postID = postID;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Only create the post list view immediately before this view is displayed.
    EPConfiguration *postListConfig = [[configuration getValueAsConfiguration:@"postList"] normalize];
    self.postListView = [[EPPostTableViewController alloc] initWithConfiguration:postListConfig];
    self.postListView.selectedID = self.postID;
    self.postListView.core = self.core;
    self.postListView.eventHandler = self;
    //self.rearViewController = self.postListView;
    // Display the post list in a navigation controller so that it has a title bar.
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.postListView];
    self.rearViewController = navController;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self applyStandardOnAppearConfiguration:configuration];
    if (tabDisplayType == TabDisplayBar) {
        [self addControls:tabBar.selectedViewController];
    }
    else {
        [self addControls:self.frontViewController];
    }
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLoad {
    [self applyStandardOnLoadConfiguration:configuration];
	// Do any additional setup after loading the view.
    [self.tabController viewDidLoad];
    tabList.tabs = self.tabController.tabs;
    self.tabs = self.tabController.tabs;
    if ([self.tabs count] > 0) {
        NSInteger selectedTabIdx = 0;
        NSString *openTab = [configuration getValueAsString:@"openTab"];
        if (openTab) {
            switch (tabDisplayType) {
                case TabDisplayBar:
                    [tabBar switchToTabWithID:openTab];
                    break;
                case TabDisplayList:
                    selectedTabIdx = [self.tabController indexOfTabWithID:openTab];
                    if (selectedTabIdx > -1) {
                        [self.tabController switchToTabWithID:openTab];
                    }
                    else {
                        selectedTabIdx = 0;
                    }
                    break;
                case TabDisplayNone:
                default:
                    break;
            }
        }
        if (tabDisplayType != TabDisplayBar) {
            self.frontViewController = [self.tabs objectAtIndex:selectedTabIdx];
        }
    }
    else {
        DDLogWarn(@"EPNavigationDrawerViewController: No tabs specified");
    }
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
}

- (BOOL)switchToTabWithID:(NSString *)tabID {
    if (tabDisplayType == TabDisplayList) {
        UIViewController* tabView = [self.tabController switchToTabWithID:tabID];
        if (tabView) {
            [tabList selectTabWithID:tabID];
            [self addControls:tabView];
            [self setFrontViewController:tabView animated:NO];
            [self hideTabList];
        }
        return !!tabView;
    }
    else {
        return [tabBar switchToTabWithID:tabID];
    }
}

- (void)showPostList {
    [self setFrontViewPosition:FrontViewPositionRightMost animated:YES];
}

- (void)hidePostList {
    [self setFrontViewPosition:FrontViewPositionLeft animated:YES];
}

- (void)togglePostList {
    [self revealToggleAnimated:YES];
}

- (void)showTabList {
    [self setFrontViewPosition:FrontViewPositionLeftSideMost animated:YES];
}

- (void)hideTabList {
    [self setFrontViewPosition:FrontViewPositionLeft animated:YES];
}

- (void)toggleTabList {
    [self rightRevealToggleAnimated:YES];
}

// Add title bar buttons and swipe controls to a tab view which is about to be made visible.
- (void)addControls:(UIViewController *)tabView {
    
    UINavigationItem *navItem;
    if ([tabView isKindOfClass:[UINavigationController class]]) {
        UIViewController *top = [(UINavigationController *)tabView topViewController];
        navItem = top.navigationItem;
    }
    else {
        navItem = tabView.navigationItem;
    }
    
    if (navItem) {
        navItem.leftBarButtonItem = postListButton;
        if (tabListButton) {
            navItem.rightBarButtonItem = tabListButton;
        }
        else if (favouriteButton) {
            navItem.rightBarButtonItem = favouriteButton;
        }
    }
    
    [tabView.view addGestureRecognizer:[self panGestureRecognizer]];
}

- (id)handleEPEvent:(EPEvent *)event {
    id result = [EPEvent notHandledResult];
    
    if ([event.name hasPrefix:EPEventPrefix]) {
        NSString *action = [event.name substringFromIndex:[EPEventPrefix length]];
        if ([@"toggle-post-list" isEqualToString:action]) {
            [self togglePostList];
            result = nil;
        }
        else if([@"toggle-tab-list" isEqualToString:action]) {
            [self toggleTabList];
            result = nil;
        }
        else if ([@"toggle-favourite" isEqualToString:action]) {
            BOOL isFavourite = [favouriteButton toggleFavourite];
            result = [NSNumber numberWithBool:isFavourite];
        }
    }
    
    // If the event is a navigation open event, and the view URI name matches the URI for this view, then
    // assume the event is targetted at this view and use it to load a new detail tabset.
    if ([event.name isEqualToString:@"nav/open"]) {
        NSString *viewName = nil;
        // Resolve the name of the event view.
        id view = [event.arguments objectForKey:@"view"];
        if ([view isKindOfClass:[NSString class]]) {
            viewName = (NSString *)viewName;
        }
        else if ([view isKindOfClass:[EPViewResource class]]) {
            viewName = ((EPViewResource *)view).uri.name;
        }
        // If the view name matches this view name...
        if ([viewName isEqualToString:self.viewURI.name]) {
            // ...then resolve the view (it will be the same type as this class)...
            EPPostDetailViewController *postDetailView = (EPPostDetailViewController *)[event resolveViewArgument];
            [postDetailView viewDidLoad];
            // ...record the current tab ID..
            NSString *currentTabID = self.tabController.currentTabID;
            // ...copy the new view's tab controller to this instance...
            self.tabController = postDetailView.tabController;
            [self.tabController viewDidLoad];
            self.postID = postDetailView.postID;
            // ...and redisplay the current tab, close the left menu.
            [self switchToTabWithID:currentTabID];
            [self hidePostList];
            result = nil;
        }
    }
    
    if ([EPEvent isNotHandled:result]) {
        result = [super handleEPEvent:event];
    }
    
    return result;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [self addControls:viewController];
}

@end
