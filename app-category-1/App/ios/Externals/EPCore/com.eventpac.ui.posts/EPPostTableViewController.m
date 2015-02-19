//
//  EPPostTableViewController.m
//  EPCore
//
//  Created by Julian Goacher on 17/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPPostTableViewController.h"
#import "UIButton+EP.h"

#define BackButtonXPos  20
#define BackButtonYPos  20

@interface EPPostTableViewController ()

@end

@implementation EPPostTableViewController

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super initWithConfiguration:config];
    if (self) {
        EPConfiguration *barButtonConfig = [config getValueAsConfiguration:@"ios:barButton"];
        if (barButtonConfig) {
            leftBarButton = [[EPBarButtonItem alloc] initWithConfiguration:barButtonConfig];
            leftBarButton.eventHandler = self;
        }
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationItem.leftBarButtonItem = leftBarButton;
}

@end
