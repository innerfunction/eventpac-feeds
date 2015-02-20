//
//  UIImageView+EP.h
//  EPCore
//
//  Created by Julian Goacher on 12/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+EP.h"
#import "EPDataModel.h"
#import "EPDataObserver.h"
#import "EPTapHandler.h"

@interface UIImageView (EP) <EPDataObserver>

@property (nonatomic, strong) EPTapHandler *tapHandler;
@property (nonatomic, strong) NSString *observes;

@end
