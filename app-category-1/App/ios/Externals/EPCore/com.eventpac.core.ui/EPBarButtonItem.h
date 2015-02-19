//
//  EPBarButtonItem.h
//  EventPacComponents
//
//  Created by Julian Goacher on 21/11/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPComponent.h"
#import "EPEventHandler.h"

@interface EPBarButtonItem : UIBarButtonItem <EPComponent> {
    UIImage *onImage;
    UIImage *offImage;
    NSString *onAction;
    NSString *offAction;
}

- (id)initWithImage:(UIImage *)image action:(NSString *)action handler:(id<EPEventHandler>)handler;

@property (nonatomic, strong) id<EPEventHandler> eventHandler;
@property (nonatomic, strong) NSString *eventAction;
@property (nonatomic, assign) BOOL state;

- (void)doAction;

+ (UIBarButtonItem *)initWithConfigurations:(NSArray *)itemConfigs;

@end
