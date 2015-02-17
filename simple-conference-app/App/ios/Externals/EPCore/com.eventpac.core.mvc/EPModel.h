//
//  EPModel.h
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPDataObserverTree.h"

@interface EPModel : NSObject {
    EPDataObserverTree *observers;
}

- (id)initWithPathSeparator:(NSString *)separator;
- (void)addDataObserver:(id<EPDataObserver>)observer forPath:(NSString *)path;
- (void)removeDataObserver:(id<EPDataObserver>)observer;
- (id)getValueForPath:(NSString *)path;
- (void)notifyDataObserversForPath:(NSString *)path;
- (void)notifyAllDataObservers;
- (void)removeAllDataObservers;

@end
