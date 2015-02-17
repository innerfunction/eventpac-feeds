//
//  EPDataObserverTree.m
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPDataObserverTree.h"
#import "NSArray+IF.h"
#import "NSDictionary+IF.h"

@implementation EPDataObserverTreeRecord

- (id)initWithDataPath:(NSString *)dataPath observer:(id<EPDataObserver>)observer {
    self = [super init];
    if (self) {
        self.dataPath = dataPath;
        self.observer = observer;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[EPDataObserverTreeRecord class]]) {
        return ((EPDataObserverTreeRecord *)object).observer == self.observer;
    }
    if ([object conformsToProtocol:@protocol(EPDataObserver)]) {
        return object == self.observer;
    }
    return NO;
}

@end

@implementation EPDataObserverTreeNode

- (id)init {
    self = [super init];
    if (self) {
        self.children = [NSDictionary dictionary];
        self.observers = [NSArray array];
        self.descendants = [NSArray array];
    }
    return self;
}

- (void)remove:(id<EPDataObserver>)observer {
    NSInteger descendantCount = [self.descendants count];
    for (NSUInteger idx = 0; idx < descendantCount; idx++) {
        EPDataObserverTreeRecord *record = [self.descendants objectAtIndex:idx];
        if (record.observer == observer) {
            self.descendants = [self.descendants arrayWithoutItem:record];
            for (id key in [self.children keyEnumerator]) {
                EPDataObserverTreeNode *child = [self.children valueForKey:key];
                [child remove:observer];
            }
            break;
        }
    }
    for (NSUInteger idx = 0; idx < [self.observers count]; idx++) {
        EPDataObserverTreeRecord *record = [self.observers objectAtIndex:idx];
        if (record.observer == observer) {
            [self.observers arrayWithoutItem:observer];
            break;
        }
    }
}

- (void)add:(id<EPDataObserver>)observer forPath:(NSString *)path isDescendant:(BOOL)isDescendant {
    EPDataObserverTreeRecord *record = [[EPDataObserverTreeRecord alloc] initWithDataPath:path observer:observer];
    if (isDescendant) {
        if (![self.descendants containsObject:record]) {
            self.descendants = [self.descendants arrayByAddingObject:record];
        }
    }
    else if (![self.observers containsObject:record]) {
        self.observers = [self.observers arrayByAddingObject:record];
    }
}

- (EPDataObserverTreeNode *)getOrCreateChildForName:(NSString *)name {
    EPDataObserverTreeNode *child = [self.children valueForKey:name];
    if (!child) {
        child = [[EPDataObserverTreeNode alloc] init];
        self.children = [self.children dictionaryWithAddedObject:child forKey:name];
    }
    return child;
}

@end

@implementation EPDataObserverTree

- (id)initWithPathSeparator:(NSString *)separator {
    self = [super init];
    if (self) {
        // Note difference here with the android framework, which allows a regex pattern for the separator
        // at this point.
        pathSeparator = separator;
        root = [[EPDataObserverTreeNode alloc] init];
    }
    return self;
}

- (void)addDataObserver:(id<EPDataObserver>)observer forPath:(NSString *)path {
    EPDataObserverTreeNode *node = root;
    for (NSString *elem in [path componentsSeparatedByString:pathSeparator]) {
        [node add:observer forPath:path isDescendant:YES];
        node = [node getOrCreateChildForName:elem];
    }
    [node add:observer forPath:path isDescendant:NO];
}

- (NSArray *)getDataObserversForPath:(NSString *)path {
    NSMutableArray *observers = [[NSMutableArray alloc] init];
    EPDataObserverTreeNode *node = root;
    if ([path length] > 0) {
        for (NSString *elem in [path componentsSeparatedByString:pathSeparator]) {
            // Add observers of the current node to the result.
            [observers addObjectsFromArray:node.observers];
            node = [node.children valueForKey:elem];
            if (!node) {
                break;
            }
        }
    }
    if (node) {
        // Add all views and descendant views of the final node to the result.
        [observers addObjectsFromArray:node.observers];
        [observers addObjectsFromArray:node.descendants];
    }
    // Note: The semantics of [EPDataObserverTreeNode add:forPath:isDescendant:] should ensure that 'observers' is a
    // list of unique items at this point.
    return observers;
}

- (NSArray *)getAllDataObservers {
    return [self getDataObserversForPath:nil];
}

- (void)removeDataObserver:(id<EPDataObserver>)observer {
    [root remove:observer];
}

@end
