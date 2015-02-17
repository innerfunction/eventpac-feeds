//
//  EPViewController.h
//  EPCore
//
//  Created by Julian Goacher on 04/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPConfiguration.h"
#import "EPComponent.h"
#import "EPController.h"

@interface EPViewControllerTimedAction : NSObject

- (id)initWithConfiguration:(EPConfiguration *)config repeats:(BOOL)repeats;

@property (nonatomic, strong) NSString *action;
@property (nonatomic) NSInteger delay;
@property (nonatomic) BOOL repeats;
@property (nonatomic, strong) NSTimer *timer;

@end

@interface EPViewController : UIViewController <EPComponent> {
    EPConfiguration *configuration;
    EPViewControllerTimedAction *ondelay;
    EPViewControllerTimedAction *onrepeat;
    NSDictionary *componentsByName;
    // Flag indicating the view's first appearance. Will be true the first time that viewWillAppear is called; is set to false
    // after viewDidAppear (so if using from this method, call [super viewDidAppear] after you use it).
    BOOL firstAppearance;
}

@end
