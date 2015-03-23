//
//  EPBarButtonItem.m
//  EventPacComponents
//
//  Created by Julian Goacher on 21/11/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "EPBarButtonItem.h"
#import "EPCore.h"

@implementation EPBarButtonItem

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super initWithImage:nil style:UIBarButtonItemStylePlain target:self action:@selector(doAction)];
    if (self) {
        EPConfiguration *stateConfig = [config getValueAsConfiguration:@"on" defaultValue:config];
        onImage = [stateConfig getValueAsImage:@"image"];
        onAction = [stateConfig getValueAsString:@"action"];
        
        if ([stateConfig hasValue:@"title"]) {
            self.title = [stateConfig getValueAsLocalizedString:@"title"];
        }
        
        stateConfig = [config getValueAsConfiguration:@"off" defaultValue:config];
        offImage = [stateConfig getValueAsImage:@"image"];
        offAction = [stateConfig getValueAsString:@"action" defaultValue:onAction];
        
        [self setState:[config getValueAsBoolean:@"initialState" defaultValue:NO]];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image action:(NSString *)action handler:(id<EPEventHandler>)handler {
    self = [super initWithImage:image style:UIBarButtonItemStyleDone target:self action:@selector(doAction)];
    if (self) {
        onImage = image;
        offImage = image;
        onAction = action;
        offAction = action;
        self.eventHandler = handler;
        [self setState:YES];
    }
    return self;
}

- (void)doAction {
    [[EPCore getCore] dispatchAction:self.eventAction toHandler:self.eventHandler];
    [self setState:!_state];
}

- (void)setState:(BOOL)state {
    _state = state;
    if (_state) {
        if (onAction) {
            self.eventAction = onAction;
        }
        if (onImage) {
            self.image = onImage;
        }
    }
    else {
        if (offAction) {
            self.eventAction = offAction;
        }
        if (offImage) {
            self.image = offImage;
        }
    }
}

- (BOOL)isEqual:(id)object {
    return [object isMemberOfClass:[EPBarButtonItem class]] && [((EPBarButtonItem *)object).eventAction isEqualToString:self.eventAction];
}

+ (UIBarButtonItem *)initWithConfigurations:(NSArray *)itemConfigs {
    if (!itemConfigs) {
        return nil;
    }
    switch ([itemConfigs count]) {
        case 0:
            return nil;
        case 1:
            return [[EPBarButtonItem alloc] initWithConfiguration:[itemConfigs objectAtIndex:0]];
        default:
            // TODO: Support for more than one action item.
            // Requires creating a view with multiple buttons, then using [UIBarButtonItem initWithCustomView:]
            return [[EPBarButtonItem alloc] initWithConfiguration:[itemConfigs objectAtIndex:0]];
    }
}

@end
