//
//  EPTabController.m
//  EventPacComponents
//
//  Created by Julian Goacher on 29/10/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "EPTabController.h"
#import "NSDictionary+IF.h"

@implementation EPTabController

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        configuration = config;
        self.tableData = [[EPTableData alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    NSMutableArray* mtabs = [[NSMutableArray alloc] init];
    NSMutableArray* mtabsData = [[NSMutableArray alloc] init];
    if (self.controlTabs) {
        [mtabsData addObjectsFromArray:self.controlTabs];
    }
    NSMutableDictionary* mtabsByID = [[NSMutableDictionary alloc] init];
    NSInteger idx = 0;
    // Iterate over each tab configuration.
    for (EPConfiguration* tabConfig in [configuration getValueAsConfigurationList:@"tabs"]) {
        // Read tab properties form the config.
        NSString* tabIdx = [NSString stringWithFormat:@"%ld", (long)idx++];
        NSString* tabID = [tabConfig getValueAsString:@"id" defaultValue:tabIdx];
        NSString* title = [tabConfig getValueAsLocalizedString:@"title"];
        UIImage* iconImage = [tabConfig getValueAsImage:@"image"];
        if (!iconImage) {
            // Backwards compatability.
            iconImage = [tabConfig getValueAsImage:@"icon"];
        }
        BOOL navigable = [tabConfig getValueAsBoolean:@"ios:navigable" defaultValue:YES];
        
        UIViewController* tabView = (UIViewController*)[tabConfig getValue:@"view"];
        
        if (tabView) {
            // Set the view's title and tab bar image.
            tabView.title = title;
            
            // If the tab is navigable then place the view in a navigation controller.
            if (navigable) {
                tabView = [[UINavigationController alloc] initWithRootViewController:tabView];
            }

            if (iconImage) {
                tabView.tabBarItem.image = iconImage;
            }
            // Add view to the list of tab views and to the tab lookup.
            [mtabs addObject:tabView];
            [mtabsByID setValue:tabView forKey:tabID];
            // Set current tab ID if not already set (i.e. this is the first tab)
            if (!self.currentTabID) {
                self.currentTabID = tabID;
            }
        }
        // Tab data dict for list based tab views.
        NSDictionary *additionalTabData = @{ @"id": tabID, @"title": title };
        NSDictionary *tabData = [(NSDictionary *)tabConfig.data extendWith:additionalTabData];
        [mtabsData addObject:tabData];
    }
    self.tabs = mtabs;
    self.tabsByID = mtabsByID;
    [self.tableData setData:mtabsData];
}

- (UIViewController*)switchToTabWithID:(NSString *)tabID {
    UIViewController* tabVC = [self.tabsByID valueForKey:tabID];
    if (tabVC) {
        // If tab contains a navigation controller then reset that to the root view.
        // TODO: Allow option to toggle this behaviour.
        if ([tabVC isKindOfClass:[UINavigationController class]]) {
            [(UINavigationController*)tabVC popToRootViewControllerAnimated:NO];
        }
        self.currentTabID = tabID;
    }
    return tabVC;
}

- (NSInteger)indexOfTabWithID:(NSString *)tabID {
    NSArray *data = self.tableData.data;
    for (NSInteger idx = 0; idx < [data count]; idx++) {
        NSDictionary *tabData = [data objectAtIndex:idx];
        if ([[tabData objectForKey:@"id"] isEqualToString:tabID]) {
            return idx;
        }
    }
    return -1;
}

@end
