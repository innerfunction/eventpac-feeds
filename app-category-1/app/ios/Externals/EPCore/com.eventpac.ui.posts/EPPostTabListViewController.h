//
//  EPPostTabListViewController.h
//  EPCore
//
//  Created by Julian Goacher on 10/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPTableViewCellFactory.h"
#import "EPTabController.h"
#import "EPComponent.h"

@class EPPostDetailViewController;

@interface EPPostTabListViewController : UITableViewController <EPComponent, UITableViewDataSource, UITableViewDelegate> {
    NSIndexPath *selected;
    EPTableViewCellFactory *cellFactory;
}

@property (nonatomic, strong) NSArray* tabs;
@property (nonatomic, strong) EPTabController* tabController;
@property (nonatomic, strong) EPPostDetailViewController* parent;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, strong) UIColor *backgroundColor;

- (void)selectTabWithID:(NSString *)tabID;

@end
