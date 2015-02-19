//
//  IFTimerManager.h
//
//  Created by Julian Goacher on 28/10/2011, 27/03/2013, 02/07/2014.
//  Copyright (c) 2011, 2013 InnerFunction Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^IFTimerAction) (void);

@interface IFTimer : NSObject {
    IFTimerAction action;
}

- (id)initWithAction:(IFTimerAction)action;
- (void)run;

@end

@interface IFTimerManager : NSObject

+ (NSTimer *)setRepeat:(double)secs action:(IFTimerAction)action;
+ (NSTimer *)setDelay:(double)secs action:(IFTimerAction)action;

@end
