//
//  EPModel.m
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPModel.h"

@implementation EPModel

- (id)initWithPathSeparator:(NSString *)separator {
    self = [super init];
    if (self) {
        observers = [[EPDataObserverTree alloc] initWithPathSeparator:separator];
    }
    return self;
}

- (void)addDataObserver:(id<EPDataObserver>)observer forPath:(NSString *)path {
    [observers addDataObserver:observer forPath:path];
    [observer notifyDataChangedAtPath:path inModel:self];
}

- (void)removeDataObserver:(id<EPDataObserver>)observer {
    if (observer) {
        [observers removeDataObserver:observer];
        [observer destroyDataObserver];
    }
}

- (id)getValueForPath:(NSString *)path {
    return nil;
}

- (void)notifyDataObserversForPath:(NSString *)path {
    // Notify all views observing this data path (or a descendant path) of the update.
    for (EPDataObserverTreeRecord *record in [observers getDataObserversForPath:path]) {
        // (The 'dataPath' parameter here allows the view to see that path of the actual updated data - this
        // can allow a view to decided not to act on the notification).
        [record.observer notifyDataChangedAtPath:path inModel:self];
    }
}

- (void)notifyAllDataObservers {
    // Notify all views observing this data path (or a descendant path) of the update.
    for (EPDataObserverTreeRecord *record in [observers getAllDataObservers]) {
        [record.observer notifyDataChangedAtPath:record.dataPath inModel:self];
    }
}

- (void)removeAllDataObservers {
    for (EPDataObserverTreeRecord *record in [observers getAllDataObservers]) {
        [self removeDataObserver:record.observer];
    }
}

@end
