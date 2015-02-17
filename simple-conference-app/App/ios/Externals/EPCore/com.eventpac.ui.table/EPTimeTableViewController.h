//
//  EPTimeTableViewController.h
//  EventPacComponents
//
//  Created by Julian Goacher on 14/11/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPTableViewController.h"
#import "ISO8601DateFormatter.h"

@interface EPTimeTableViewController : EPTableViewController <EPTableDataDelegate> {
    NSDateFormatter *dateFormatter;
    NSDateFormatter *timeFormatter;
    ISO8601DateFormatter *dateParser;
}

@property (nonatomic, assign) BOOL scrollToNow;
@property (nonatomic, assign) BOOL hidePastRows;
@property (nonatomic, strong) NSString *startTimeRef;
@property (nonatomic, strong) NSString *endTimeRef;

@end
