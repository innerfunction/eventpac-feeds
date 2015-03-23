//
//  EPAppDelegate.h
//  EPCore
//
//  Created by Julian Goacher on 10/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPCore.h"

@interface EPAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) EPCore *core;

@end
