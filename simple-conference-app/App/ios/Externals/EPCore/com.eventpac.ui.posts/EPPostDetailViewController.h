//
//  EPPostDetailViewController.h
//  EPCore
//
//  Created by Julian Goacher on 10/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//
// DEPRECATED Use EPSlideNavigationHubController instead

#import <Foundation/Foundation.h>
#import "SWRevealViewController.h"
#import "EPComponent.h"
#import "EPConfiguration.h"
#import "EPTabController.h"
#import "EPTabBarController.h"
#import "EPView.h"
#import "EPTableViewCellFactory.h"
#import "EPPostTabListViewController.h"
#import "EPBarButtonItem.h"
#import "EPFavouriteBarButtonItem.h"

typedef enum NSInteger {
    TabDisplayNone,
    TabDisplayList,
    TabDisplayBar
} TabDisplayType;

@interface EPPostDetailViewController : SWRevealViewController <EPComponent, EPView, EPEventHandler, UITabBarControllerDelegate> {
    EPConfiguration *configuration;
    EPPostTabListViewController *tabList;
    EPTabBarController *tabBar;
    EPBarButtonItem *postListButton;
    EPBarButtonItem *tabListButton;
    EPFavouriteBarButtonItem *favouriteButton;
    TabDisplayType tabDisplayType;
}

@property (nonatomic, strong) EPTableViewController *postListView;
@property (nonatomic, strong) EPTabController *tabController;
@property (nonatomic, strong) NSArray *tabs;
@property (nonatomic, strong) NSString *postID;

- (BOOL)switchToTabWithID:(NSString*)tabID;
- (void)showPostList;
- (void)hidePostList;
- (void)togglePostList;
- (void)showTabList;
- (void)hideTabList;
- (void)toggleTabList;

@end
