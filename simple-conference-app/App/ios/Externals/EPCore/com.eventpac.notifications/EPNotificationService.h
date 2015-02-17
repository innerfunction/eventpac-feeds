//
//  EPNotificationService.h
//  EPCore
//
//  Created by Julian Goacher on 07/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPService.h"
#import "EPEventHandler.h"
#import "EPDBController.h"
#import "ISO8601DateFormatter.h"

@interface EPNotificationService : NSObject <EPService, EPEventHandler> {
    NSMutableDictionary *favouriteNotificationsByPostID;
    NSString *postTableName;
    NSString *selectFavouritesSQL;
    EPDBController *db;
    NSDateFormatter *timeFormat;
    ISO8601DateFormatter *dbDateTimeParser;
}

- (BOOL)togglePostFavouriteStatus:(NSString *)postID;
- (BOOL)favouriteStatusForPost:(NSString *)postID;

@end
