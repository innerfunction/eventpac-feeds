//
//  EPAppDelegate.m
//  EPCore
//
//  Created by Julian Goacher on 10/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPAppDelegate.h"
#import "EPAlert.h"

@implementation EPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.core = [EPCore startWithConfiguration:@"app:/common/configuration.json" window:self.window];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self.core stopService];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    EPAlertAction alertAction = ^(BOOL ok) {
        if (ok) {
            NSString *action = [notification.userInfo valueForKey:@"action"];
            if (action) {
                [self.core dispatchAction:action];
            }
        }
    };
    // See http://stackoverflow.com/questions/23009348/ios-how-can-i-tell-if-a-local-notification-caused-my-app-to-enter-foreground
    UIApplicationState state = [application applicationState];
    if (state == UIApplicationStateActive ) {
        // Else app is in the foregound. Display an alert displaying the notification message, and continue with
        // the notification action if the user pressed ok.
        [EPAlert showAlertForNotification:notification action:alertAction];
    }
    else {
        // If app is in the background or inactive then continue to perform the notification action.
        alertAction( YES );
    }
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

@end
