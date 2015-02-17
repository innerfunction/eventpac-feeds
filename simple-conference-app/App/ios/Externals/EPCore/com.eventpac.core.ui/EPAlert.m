//
//  EPAlert.m
//  EPCore
//
//  Created by Julian Goacher on 02/11/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPAlert.h"

@implementation EPAlert

- (id)initWithMessage:(NSString *)message okTitle:(NSString *)okTitle {
    NSString *cancelTitle = NSLocalizedString(@"Cancel", @"");
    return [super initWithTitle:nil message:message delegate:self cancelButtonTitle:cancelTitle otherButtonTitles: okTitle, nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.action) {
        self.action( buttonIndex == 1 );
    }
}

+ (EPAlert *)showAlertWithMessage:(NSString *)message okTitle:(NSString *)okTitle action:(EPAlertAction)action {
    message = NSLocalizedString(message, @"");
    okTitle = NSLocalizedString(okTitle, @"");
    EPAlert *alert = [[EPAlert alloc] initWithMessage:message okTitle:okTitle];
    alert.action = action;
    [alert show];
    return alert;
}

+ (EPAlert *)showAlertForNotification:(UILocalNotification *)notification action:(EPAlertAction)action {
    EPAlert *alert = [[EPAlert alloc] initWithMessage:notification.alertBody okTitle:notification.alertAction];
    alert.action = action;
    [alert show];
    return alert;
}

@end
