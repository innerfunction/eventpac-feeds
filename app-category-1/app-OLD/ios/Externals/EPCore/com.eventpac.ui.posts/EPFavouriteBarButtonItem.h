//
//  EPFavouriteBarButtonItem.h
//  EPCore
//
//  Created by Julian Goacher on 10/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "EPFavouriteBarButtonItem.h"
#import "EPComponent.h"
#import "EPNotificationService.h"

@interface EPFavouriteBarButtonItem : UIBarButtonItem <EPComponent> {
    EPCore *core;
    EPNotificationService *notificationService;
    UIImage *onImage;
    UIImage *offImage;
    NSString *onMessage;
    NSString *offMessage;
}

@property (nonatomic, strong) NSString *postID;

- (BOOL)toggleFavourite;

@end
