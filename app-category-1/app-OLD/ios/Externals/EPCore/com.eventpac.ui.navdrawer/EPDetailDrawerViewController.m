//
//  EPDetailDrawerViewController.m
//  EPCore
//
//  Created by Julian Goacher on 10/08/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPDetailDrawerViewController.h"
#import "EPConfiguration.h"
#import "UIViewController+EP.h"
#import "EPViewResource.h"

#define ParentDrawerToggleButtonYPos    150
#define ParentDrawerToggleButtonWidth   20
#define ParentDrawerToggleButtonHeight  64

@interface EPDetailDrawerViewController ()

- (void)toggleParentDrawer;

@end

@implementation EPDetailDrawerViewController

@synthesize core;

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super initWithConfiguration:config defaultPosition:@"right"];
    if (self) {
        if ([config hasValue:@"ios:parentDrawerToggleButtonImage"]) {
            parentDrawerToggleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, ParentDrawerToggleButtonYPos, ParentDrawerToggleButtonWidth, ParentDrawerToggleButtonHeight)];
            [parentDrawerToggleButton setBackgroundImage:[config getValueAsImage:@"ios:parentDrawerToggleButtonImage"] forState:UIControlStateNormal];
            [parentDrawerToggleButton addTarget:self action:@selector(toggleParentDrawer) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Only create the left-side list view immediately prior to this view being displayed.
    // This is because in when selecting list items that update the detail, this view is only used
    // to configure the active detail drawer view.
    self.listView = [[EPTableViewController alloc] initWithConfiguration:[configuration getValueAsConfiguration:@"list"]];
    self.listView.core = self.core;
    self.listView.eventHandler = self;
    self.rearViewController = self.listView;
    self.listView.tableView.delegate = self;

    if (self.parentNavigationDrawer && parentDrawerToggleButton) {
        [self.listView.tableView addSubview:parentDrawerToggleButton];
    }
    else {
        [parentDrawerToggleButton removeFromSuperview];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (parentDrawerToggleButton) {
        CGRect frame = parentDrawerToggleButton.frame;
        frame.origin.y = scrollView.contentOffset.y + ParentDrawerToggleButtonYPos;
        parentDrawerToggleButton.frame = frame;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.listView tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)toggleParentDrawer {
    [self.parentNavigationDrawer toggleMenu];
}

- (id)handleEPEvent:(EPEvent *)event {
    id result = [EPEvent notHandledResult];
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
            EPDetailDrawerViewController *detailDrawerView = (EPDetailDrawerViewController *)[event resolveViewArgument];
            // ...copy the new view's tab controller to this instance...
            self.tabController = detailDrawerView.tabController;
            // ...and redisplay the current tab, close the left menu.
            [self switchToTabWithID:currentTabID];
            [self hideMenu];
            result = nil;
        }
    }
    if ([EPEvent isNotHandled:result]) {
        result = [super handleEPEvent:event];
    }
    return result;
}

@end
