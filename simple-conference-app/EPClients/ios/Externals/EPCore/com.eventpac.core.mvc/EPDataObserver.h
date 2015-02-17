//
//  EPObserver.h
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EPModel;

@protocol EPDataObserver <NSObject>

- (void)notifyDataChangedAtPath:(NSString *)path inModel:(EPModel *)model;

- (void)destroyDataObserver;

@optional

// Set the path that the data observer observes.
- (void)setObserves:(NSString *)path;

@end
