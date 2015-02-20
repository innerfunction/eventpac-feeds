//
//  EPNavigationDrawerListViewController.m
//  EPCore
//
//  Created by Julian Goacher on 15/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPNavigationDrawerListViewController.h"
#import "UIColor+IF.h"
#import "EPNavigationDrawerViewController.h"

#define BackTabID (@"EPNavigationDrawerListViewController.backTab")

@implementation EPNavigationDrawerListViewController

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        cellFactory = [[EPTableViewCellFactory alloc] initWithConfiguration:config];
        self.backgroundColor = [config getValueAsColor:@"row.backgroundColor" defaultValue:[UIColor colorForHex:@"#000000"]];
        NSNumber *nwidth = [config getValueAsNumber:@"width"];
        self.width = nwidth != nil ? [nwidth floatValue] : 0.0f;
        selected = [NSIndexPath indexPathForItem:0 inSection:0];
        backMenuItem = [config getValueAsConfiguration:@"ios:backMenuItem"];
    }
    return self;
}

- (void)setTabController:(EPTabController *)tabController {
    _tabController = tabController;
    cellFactory.tableData = tabController.tableData;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // If the list is being presented in a right hand position then display further to the right (i.e.
    // increase origin.x) so that the list icons are visible.
    if (self.parent.position == EPNavigationDrawerListPositionRight) {
        CGRect frame = self.tableView.frame;
        if (frame.origin.x == 0) {
            CGFloat x = (frame.size.width - self.width);
            self.tableView.frame = CGRectMake( x, 0, frame.size.width - x, frame.size.height);
        }
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

    if (self.parent.parentNavigationDrawer) {
        NSString *title = NSLocalizedString(@"Back",@"");
        NSString *image = nil;
        if (backMenuItem) {
            title = [backMenuItem getValueAsLocalizedString:@"title"];
            image = [backMenuItem getValueAsString:@"image"];
        }
        NSMutableDictionary *backTab = [[NSMutableDictionary alloc] init];
        [backTab setObject:BackTabID forKey:@"id"];
        [backTab setObject:title forKey:@"title"];
        if (image) {
            [backTab setObject:image forKey:@"image"];
        }
        _tabController.controlTabs = @[ backTab ];
    }
    
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
    if ([BackTabID isEqualToString:tabID]) {
        [_parent.parentNavigationDrawer toggleMenu];
    }
    else {
        [_parent switchToTabWithID:tabID];
        selected = indexPath;
    }
}

@end
