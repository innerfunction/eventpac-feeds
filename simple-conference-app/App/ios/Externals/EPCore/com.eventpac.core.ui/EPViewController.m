//
//  EPViewController.m
//  EPCore
//
//  Created by Julian Goacher on 04/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPViewController.h"
#import "UIViewController+EP.h"
#import "EPCore.h"
#import "IFTimer.h"
#import "IFCore.h"
#import "EPViewResource.h"
#import "EPBarButtonItem.h"
#import "UIView+EP.h"

static const int ddLogLevel = IFCoreLogLevel;

#define DefaultTimedActionDelay 5

@implementation EPViewControllerTimedAction

- (id)initWithConfiguration:(EPConfiguration *)config repeats:(BOOL)repeats {
    self = [super init];
    if (self) {
        self.action = [config getValueAsString:@"action"];
        self.delay = [[config getValueAsNumber:@"delay" defaultValue:[NSNumber numberWithInt:DefaultTimedActionDelay]] integerValue];
        self.repeats = repeats;
    }
    return self;
}

@end

@implementation EPViewController

@synthesize core;

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        configuration = config;
        [self applyStandardConfiguration:config];
        if ([config hasValue:@"ondelay"]) {
            ondelay = [[EPViewControllerTimedAction alloc] initWithConfiguration:[config getValueAsConfiguration:@"ondelay"] repeats:NO];
        }
        if ([config hasValue:@"onrepeat"]) {
            onrepeat = [[EPViewControllerTimedAction alloc] initWithConfiguration:[config getValueAsConfiguration:@"onrepeat"] repeats:YES];
        }
        firstAppearance = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyStandardOnLoadConfiguration:configuration];
    [self.view configureWithConfiguration:configuration eventHandler:self];
    [self.view layoutWithConfiguration:configuration owner:self];
    componentsByName = [self.view layoutSubviewsUsingConfiguration:configuration container:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self applyStandardOnAppearConfiguration:configuration];
    if (ondelay) {
        ondelay.timer = [IFTimerManager setDelay:(double)ondelay.delay action:^{
            [[EPCore getCore] dispatchAction:ondelay.action toHandler:self];
        }];
    }
    if (onrepeat) {
        IFTimerAction onrepeatAction = ^{
            [[EPCore getCore] dispatchAction:onrepeat.action toHandler:self];
        };
        onrepeat.timer =[IFTimerManager setRepeat:(double)onrepeat.delay action:onrepeatAction];
        // Run the first occurrence of the repeat action immediately.
        onrepeatAction();
    }
    firstAppearance = NO;
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [ondelay.timer invalidate];
    [onrepeat.timer invalidate];
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    if (self.navigationItem) {
        self.navigationItem.title = title;
    }
}

@end
