//
//  EPPostTabListViewController.m
//  EPCore
//
//  Created by Julian Goacher on 10/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPPostTabListViewController.h"
#import "UIColor+IF.h"
#import "EPPostDetailViewController.h"

@implementation EPPostTabListViewController

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        cellFactory = [[EPTableViewCellFactory alloc] initWithConfiguration:config];
        self.backgroundColor = [config getValueAsColor:@"row.backgroundColor" defaultValue:[UIColor colorForHex:@"#000000"]];
        NSNumber *nwidth = [config getValueAsNumber:@"width"];
        self.width = nwidth != nil ? [nwidth floatValue] : 0.0f;
        selected = [NSIndexPath indexPathForItem:0 inSection:0];
    }
    return self;
}

- (void)setTabController:(EPTabController *)tabController {
    _tabController = tabController;
    cellFactory.tableData = tabController.tableData;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // The menu list is presented on the RHS, and so needs to be offset slightly to the right to ensure
    // then the list icons are visible.
    CGRect frame = self.tableView.frame;
    if (frame.origin.x == 0) {
        CGFloat x = (frame.size.width - self.width);
        self.tableView.frame = CGRectMake( x, 0, frame.size.width - x, frame.size.height);
    }
}

- (void)selectTabWithID:(NSString *)tabID {
    NSInteger idx = [_tabController indexOfTabWithID:tabID];
    if (idx > -1) {
        selected = [NSIndexPath indexPathForRow:idx inSection:0];
        [self.tableView selectRowAtIndexPath:selected animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // This necessary to ensure that table displays below the status bar.
    self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    self.tableView.backgroundColor = self.backgroundColor;
    // Hide table row separators after the last menu item.
    // See http://stackoverflow.com/a/5377569
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView selectRowAtIndexPath:selected animated:YES scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_tabController.tableData sectionCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_tabController.tableData sectionSize:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [_tabController.tableData sectionTitle:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [cellFactory resolveCellForTable:tableView indexPath:indexPath];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    NSDictionary *rowData = [_tabController.tableData dataForPath:indexPath];
    NSString *tabID = [rowData valueForKey:@"id"];
    [self.parent switchToTabWithID:tabID];
    selected = indexPath;
}

@end
