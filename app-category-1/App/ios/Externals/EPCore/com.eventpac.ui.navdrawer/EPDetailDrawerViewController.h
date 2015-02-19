//
//  EPDetailDrawerViewController.h
//  EPCore
//
//  Created by Julian Goacher on 10/08/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPNavigationDrawerViewController.h"
#import "EPTableViewController.h"
#import "EPEventHandler.h"

@interface EPDetailDrawerViewController : EPNavigationDrawerViewController <EPEventHandler, UITableViewDelegate> {
    UIButton *parentDrawerToggleButton;
}

@property (nonatomic, strong) EPTableViewController *listView;

@end
