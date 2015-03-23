//
//  EPTabBarController.m
//  EventPacComponents
//
//  Created by Julian Goacher on 12/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "EPTabBarController.h"
#import "UIViewController+EP.h"

@implementation EPTabBarController

- (id)initWithConfiguration:(EPConfiguration *)config {
    // Tab controller must be initialized first because [super init] will call [self viewDidLoad],
    // which needs the tab controller to be in place.
    self.tabController = [[EPTabController alloc] initWithConfiguration:config];
    self = [super init];
    if (self) {
        configuration = config;
        [self applyStandardConfiguration:configuration];
    }
    return self;
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyStandardOnLoadConfiguration:configuration];
    self.navigationController.navigationBarHidden = YES;

    // Initialize tabs.
    [self.tabController viewDidLoad];
    [self setViewControllers:self.tabController.tabs];
    
    // Set title bar colour for more tab screen.
    if ([configuration hasValue:@"titleBarColor"]) {
        self.moreNavigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        self.moreNavigationController.navigationBar.tintColor = [configuration getValueAsColor:@"titleBarColor"];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.navigationController) {
        /*
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(back)];
        */
        UIBarButtonItem *leftBarButton = self.navigationItem.leftBarButtonItem;
        if (leftBarButton) {
            for (UIViewController *tabViewController in self.viewControllers) {
                UINavigationItem *navigationItem;
                if ([tabViewController isKindOfClass:[UINavigationController class]]) {
                    navigationItem = [(UINavigationController *)tabViewController topViewController].navigationItem;
                }
                else {
                    navigationItem = tabViewController.navigationItem;
                }
                //navigationItem.leftBarButtonItem = backButton;
                navigationItem.leftBarButtonItem = leftBarButton;
            }
        }
    }
}

- (BOOL)switchToTabWithID:(NSString*)tabID {
    UIViewController* tabView = [self.tabController switchToTabWithID:tabID];
    if (tabView) {
        self.selectedViewController = tabView;
    }
    return !!tabView;
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
