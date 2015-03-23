//
//  IFTimerManager.m
//
//  Created by Julian Goacher on 28/10/2011, 27/03/2013, 02/07/2014.
//  Copyright (c) 2011, 2013 InnerFunction Ltd. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "IFTimer.h"

@implementation IFTimer

- (id)initWithAction:(IFTimerAction)_action {
    if ((self = [super init])) {
        action = _action;
    }
    return self;
}

- (void)run {
    action();
}

@end

@implementation IFTimerManager

+ (NSTimer*)setRepeat:(double)secs action:(IFTimerAction)action {
    IFTimer *timer = [[IFTimer alloc] initWithAction:action];
    NSTimeInterval time = (NSTimeInterval)secs;
    NSTimer *result = [NSTimer timerWithTimeInterval:time target:timer selector:@selector(run) userInfo:nil repeats:YES];
    NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
    [runLoop addTimer:result forMode:NSRunLoopCommonModes];
    [runLoop addTimer:result forMode:UITrackingRunLoopMode];
    return result;
}

+ (NSTimer*)setDelay:(double)secs action:(IFTimerAction)action {
    IFTimer *timer = [[IFTimer alloc] initWithAction:action];
    NSTimeInterval time = (NSTimeInterval)secs;
    NSTimer *result = [NSTimer timerWithTimeInterval:time target:timer selector:@selector(run) userInfo:nil repeats:NO];
    NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
    [runLoop addTimer:result forMode:NSRunLoopCommonModes];
    [runLoop addTimer:result forMode:UITrackingRunLoopMode];
    return result;    
}

@end
