//
//  EPNotificationService.m
//  EPCore
//
//  Created by Julian Goacher on 07/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPNotificationService.h"
#import "EPCore.h"
#import "NSDictionary+IF.h"
#import "IFStringTemplate.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

#define Tag @"EPNotificationService"

@interface EPNotificationService()

- (void)refreshFavouriteNotifications;
- (UILocalNotification *)createNotificationForPost:(NSDictionary *)post;

@end

@implementation EPNotificationService

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        favouriteNotificationsByPostID = [[NSMutableDictionary alloc] init];
        
        postTableName = [config getValueAsString:@"postTableName" defaultValue:@"posts"];
        selectFavouritesSQL = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE favourite=1", postTableName];
        
        timeFormat = [[NSDateFormatter alloc] init];
        [timeFormat setDateStyle:NSDateFormatterNoStyle];
        [timeFormat setTimeStyle:NSDateFormatterShortStyle];
        
        dbDateTimeParser = [[ISO8601DateFormatter alloc] init];
    }
    return self;
}

- (void)startService {
    EPCore *core = [EPCore getCore];
    EPController *mvc = [core.servicesByName valueForKey:@"mvc"];
    db = mvc.dbController;
    [self refreshFavouriteNotifications];
}

- (void)stopService {}

- (id)handleEPEvent:(EPEvent *)event {
    id result = [EPEvent notHandledResult];
    if ([@"notification/toggle" isEqualToString:event.action]) {
        NSString *postID = [(IFResource *)[event.arguments valueForKey:@"postID"] asString];
        BOOL favourite = [self togglePostFavouriteStatus:postID];
        result = [NSNumber numberWithBool:favourite];
    }
    else if ([@"notification/refresh" isEqualToString:event.action]) {
        [self refreshFavouriteNotifications];
        result = nil;
    }
    return result;
}

- (BOOL)togglePostFavouriteStatus:(NSString *)postID {
    BOOL status = NO;
    NSDictionary *post = [db readRecordWithID:postID fromTable:postTableName];
    if (post) {
        BOOL favourite = !ValueAsBoolean(post, @"favourite");
        NSNumber *_favourite = [NSNumber numberWithBool:favourite];
        post = [post dictionaryWithAddedObject:_favourite forKey:@"favourite"];
        if ([db updateValues:post inTable:postTableName]) {
            status = favourite;
            if (favourite) {
                if (GetBooleanSetting(@"favourites.localNotificationsEnabled")) {
                    UILocalNotification *notification = [self createNotificationForPost:post];
                    if (notification) {
                        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
                    }
                }
            }
            else {
                UILocalNotification *notification = [favouriteNotificationsByPostID valueForKey:postID];
                if (notification) {
                    [[UIApplication sharedApplication] cancelLocalNotification:notification];
                }
            }
        }
        else {
            // Result needs to reflect the actual favourite value in the db, so reverse the toggle.
            status = !favourite;
        }
    }
    return status;
}

- (BOOL)favouriteStatusForPost:(NSString *)postID {
    BOOL status = NO;
    NSDictionary *post = [db readRecordWithID:postID fromTable:postTableName];
    if (post) {
        status = ValueAsBoolean(post, @"favourite");
    }
    return status;
}

- (void)refreshFavouriteNotifications {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    if (GetBooleanSetting(@"favourites.localNotificationsEnabled")) {
        
        NSArray *favourites = [db performQuery:selectFavouritesSQL withParams:nil];
        
        NSMutableArray *notifications = [[NSMutableArray alloc] initWithCapacity:[favourites count]];
        
        for (NSDictionary *favourite in favourites) {
            UILocalNotification *notification = [self createNotificationForPost:favourite];
            if (notification) {
                [notifications addObject:notification];
            }
        }
        
        [UIApplication sharedApplication].scheduledLocalNotifications = notifications;
    }
    else {
        NSLog(@"%@ Favourite local notifications disabled", Tag);
    }
}

- (UILocalNotification *)createNotificationForPost:(NSDictionary *)post {
    
    double alarmTrigger = GetNumberSetting(@"favourites.alarmTrigger");
    
    UILocalNotification *notification = nil;
    NSTimeZone *timeZone;
    NSDate *startTime = [dbDateTimeParser dateFromString:[post valueForKey:@"startTime"] timeZone:&timeZone];
    /* TESTAGE
    NSDate *startTime = [dbDateTimeParser dateFromString:@"2014-11-02 18:04:10" timeZone:&timeZone];
    alarmTrigger = 0;
    */
    // Check that we have a start time, and that it is a future time.
    if (startTime && [startTime compare:[NSDate date]] == NSOrderedDescending) {
        notification = [[UILocalNotification alloc] init];
        notification.fireDate = [startTime dateByAddingTimeInterval:(NSTimeInterval)(-1 * alarmTrigger)];
        notification.timeZone = timeZone;
        
        NSString *time = [timeFormat stringFromDate:startTime];
        NSString *title = [post valueForKey:@"title"];
        NSString *description = [post valueForKey:@"description"];
        NSString *message = NSLocalizedString(@"FavouriteLocalNotificationMessage", @"");
        NSDictionary *params = @{ @"title": title, @"description": description, @"time": time };        
        NSString *action = [post valueForKey:@"action"];
        
        notification.alertBody = [IFStringTemplate render:message context:params];
        notification.alertAction = NSLocalizedString(@"FavouriteLocalNotificationAction", @"");
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.applicationIconBadgeNumber = 1;
        notification.userInfo = @{ @"action": action };

        [favouriteNotificationsByPostID setObject:notification forKey:[post valueForKey:@"id"]];
    }
    return notification;
}

@end
