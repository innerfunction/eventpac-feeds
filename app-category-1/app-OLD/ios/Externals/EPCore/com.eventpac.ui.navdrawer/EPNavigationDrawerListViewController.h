//
//  EPNavigationDrawerListViewController.h
//  EPCore
//
//  Created by Julian Goacher on 15/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPTableViewCellFactory.h"
#import "EPTabController.h"
#import "EPComponent.h"

@class EPNavigationDrawerViewController;

@interface EPNavigationDrawerListViewController : UITableViewController <EPComponent, UITableViewDataSource, UITableViewDelegate> {
    NSIndexPath *selected;
    EPTableViewCellFactory *cellFactory;
    EPConfiguration *backMenuItem;
}

@property (nonatomic, strong) NSArray* tabs;
@property (nonatomic, strong) EPTabController* tabController;
@property (nonatomic, strong) EPNavigationDrawerViewController* parent;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, strong) UIColor *backgroundColor;

- (void)selectTabWithID:(NSString *)tabID;

@end
