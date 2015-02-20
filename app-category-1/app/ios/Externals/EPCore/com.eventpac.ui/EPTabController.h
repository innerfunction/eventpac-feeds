//
//  EPTabController.h
//  EventPacComponents
//
//  Created by Julian Goacher on 29/10/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "EPConfiguration.h"
#import "EPTableData.h"
#import "EPComponent.h"

/**
 * Class providing common functionality used to initialize and control sets of 'tabs'
 * (i.e. screens).
 */
@interface EPTabController : NSObject <EPComponent> {
    EPConfiguration* configuration;
}

@property (nonatomic, strong) NSArray* controlTabs;
@property (nonatomic, strong) NSArray* tabs;
@property (nonatomic, strong) NSDictionary* tabsByID;
@property (nonatomic, strong) EPTableData* tableData;
@property (nonatomic, strong) NSString *currentTabID;

- (void)viewDidLoad;
- (UIViewController*)switchToTabWithID:(NSString*)tabID;
- (NSInteger)indexOfTabWithID:(NSString *)tabID;

@end
