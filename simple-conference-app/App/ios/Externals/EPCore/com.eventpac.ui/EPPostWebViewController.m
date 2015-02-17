//
//  EPPostWebViewController.m
//  EPCore
//
//  Created by Julian Goacher on 20/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPPostWebViewController.h"
#import "UIViewController+EP.h"

@interface EPPostWebViewController ()

@end

@implementation EPPostWebViewController

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super initWithConfiguration:config];
    if (self) {
        self.postID = [configuration getValueAsString:@"postID"];
        EPConfiguration *buttonConfig = [configuration getValueAsConfiguration:@"favouriteButton"];
        if (buttonConfig) {
            favouriteButton = [[EPFavouriteBarButtonItem alloc] initWithConfiguration:buttonConfig];
        }
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.rightBarButtonItem = favouriteButton;
    favouriteButton.postID = self.postID;
}

@end
