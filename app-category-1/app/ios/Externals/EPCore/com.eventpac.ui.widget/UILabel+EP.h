//
//  UILabel+EP.h
//  EPCore
//
//  Created by Julian Goacher on 12/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+EP.h"
#import "EPDataModel.h"
#import "EPDataObserver.h"

@interface UILabel (EP) <EPDataObserver>

@property (nonatomic, strong) NSString *observes;

@end
