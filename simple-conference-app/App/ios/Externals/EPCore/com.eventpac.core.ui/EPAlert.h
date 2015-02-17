//
//  EPAlert.h
//  EPCore
//
//  Created by Julian Goacher on 02/11/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^EPAlertAction) (BOOL);

@interface EPAlert : UIAlertView <UIAlertViewDelegate>

- (id)initWithMessage:(NSString *)message okTitle:(NSString *)okTitle;

@property (nonatomic, copy) EPAlertAction action;

+ (EPAlert *)showAlertWithMessage:(NSString *)message okTitle:(NSString *)okTitle action:(EPAlertAction)action;
+ (EPAlert *)showAlertForNotification:(UILocalNotification *)notification action:(EPAlertAction)action;

@end
