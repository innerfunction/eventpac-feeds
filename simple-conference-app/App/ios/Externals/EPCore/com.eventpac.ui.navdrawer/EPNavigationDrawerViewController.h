//
//  EPTabSlideViewController.h
//  EventPacComponents
//
//  Created by Julian Goacher on 29/10/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "SWRevealViewController.h"
#import "EPComponent.h"
#import "EPConfiguration.h"
#import "EPTabController.h"
#import "EPView.h"
#import "EPTableViewCellFactory.h"
#import "EPNavigationDrawerListViewController.h"
#import "EPBarButtonItem.h"

typedef enum {
    EPNavigationDrawerListPositionLeft,
    EPNavigationDrawerListPositionRight
} EPNavigationDrawerListPosition;

@interface EPNavigationDrawerViewController : SWRevealViewController <EPComponent, EPView, EPEventHandler> {
    EPConfiguration *configuration;
    EPNavigationDrawerListViewController *tabList;
    NSString *currentTabID;
}

@property (nonatomic, strong) EPTabController *tabController;
@property (nonatomic, assign) EPNavigationDrawerListPosition position;
@property (nonatomic, strong) NSArray *tabs;
@property (nonatomic, strong) EPBarButtonItem *menuButton;
@property (nonatomic, strong) EPNavigationDrawerViewController *parentNavigationDrawer;

- (id)initWithConfiguration:(EPConfiguration *)config defaultPosition:(NSString *)defaultPosition;
- (BOOL)switchToTabWithID:(NSString*)tabID;
- (void)showMenu;
- (void)hideMenu;
- (void)toggleMenu;

@end
