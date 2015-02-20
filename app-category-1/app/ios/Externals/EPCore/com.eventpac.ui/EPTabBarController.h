//
//  EPTabBarController.h
//  EventPacComponents
//
//  Created by Julian Goacher on 12/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "EPConfiguration.h"
#import "EPTabController.h"
#import "EPComponent.h"

@interface EPTabBarController : UITabBarController <EPComponent> {
    EPConfiguration *configuration;
}

@property (nonatomic, strong) EPTabController *tabController;

- (BOOL)switchToTabWithID:(NSString *)tabID;
- (void)back;

@end
