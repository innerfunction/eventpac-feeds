//
//  EPTimeTableViewController.m
//  EventPacComponents
//
//  Created by Julian Goacher on 14/11/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "EPTimeTableViewController.h"

@implementation EPTimeTableViewController

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super initWithConfiguration:config];
    if (self) {
        self.scrollToNow = [config getValueAsBoolean:@"scrollToNow" defaultValue:YES];
        self.hidePastRows = [config getValueAsBoolean:@"hidePastRows" defaultValue:NO];
        self.startTimeRef = [config getValueAsString:@"startTimeRef" defaultValue:@"startTime"];
        if (!self.startTimeRef) {
            self.startTimeRef = [config getValueAsString:@"timeRef" defaultValue:@"time"];
        }
        self.endTimeRef = [config getValueAsString:@"endTimeRef" defaultValue:@"endTime"];
        tableData.delegate = self;
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
        timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        [timeFormatter setDateStyle:NSDateFormatterNoStyle];
        
        dateParser = [[ISO8601DateFormatter alloc] init];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.scrollToNow) {
        NSIndexPath *path = [self.tableView indexPathForSelectedRow];
        if (!path) {
            path = [self indexPathForFirstRowWithDisplayMode:@"now"];
            if (!path) {
                // If no "now" row then try finding the first "future" row - e.g. the next event.
                path = [self indexPathForFirstRowWithDisplayMode:@"future"];
            }
            if (path) {
                [self.tableView scrollToRowAtIndexPath:path
                                      atScrollPosition:UITableViewScrollPositionTop
                                              animated:YES];
            }
        }
    }
}

- (NSString *)displayModeForIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *rowData = [tableData dataForPath:indexPath];
    NSDate *startTime = [rowData getValueAsDate:self.startTimeRef];
    NSTimeInterval interval = [startTime timeIntervalSinceNow];
    if (interval > 0) {
        // Item start time is in the future.
        return @"future";
    }
    // Else item start time is now or in the past.
    NSDate *endTime = [rowData getValueAsDate:self.endTimeRef];
    // If no end time found, then attempt reading the start time of the next item.
    if (!endTime) {
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:(indexPath.row + 1) inSection:indexPath.section];
        NSDictionary *nextRowData = [tableData dataForPath:nextIndexPath];
        endTime = [nextRowData getValueAsDate:self.startTimeRef];
    }
    if (endTime) {
        interval = [endTime timeIntervalSinceNow];
        if (interval < 0) {
            return @"past";
        }
    }
    return @"now";
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.hidePastRows) {
        NSString *mode = [self displayModeForIndexPath:indexPath];
        if ([@"past" isEqualToString:mode]) {
            return 0;
        }
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.hidePastRows) {
        // Get the first row of the specified section. If it is in the past then hide the section
        // title. Note that this will mean that the section title won't be displayed for any of the
        // current day's events.
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
        NSDictionary *rowData = [tableData dataForPath:indexPath];
        NSDate *startTime = [rowData getValueAsDate:self.startTimeRef];
        NSTimeInterval interval = [startTime timeIntervalSinceNow];
        if (interval < 0) {
            return 0;
        }
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}

#pragma mark - EPTableDataDelegate -----
- (id)resolveTableDataSectionTitle:(NSDictionary *)section tableData:(EPTableData *)tableData {
    NSString *startTime = [section valueForKey:self.startTimeRef];
    if (startTime) {
        NSDate *startDate = [dateParser dateFromString:startTime];
        return [dateFormatter stringFromDate:startDate];
    }
    return nil;
}

- (id)resolveTableDataRef:(NSString *)ref on:(NSDictionary *)cellData tableData:(EPTableData *)tableData {
    if ([@"description" isEqualToString:ref]) {
        NSDate *startTime = [dateParser dateFromString:[cellData valueForKey:self.startTimeRef]];
        NSDate *endTime = nil;
        if (self.endTimeRef) {
            endTime = [dateParser dateFromString:[cellData valueForKey:self.endTimeRef]];
        }
        if (endTime) {
            return [NSString stringWithFormat:@"%@ - %@", [timeFormatter stringFromDate:startTime], [timeFormatter stringFromDate:endTime]];
        }
        return [NSString stringWithFormat:@"%@", [timeFormatter stringFromDate:startTime]];
    }
    return nil;
}

@end
