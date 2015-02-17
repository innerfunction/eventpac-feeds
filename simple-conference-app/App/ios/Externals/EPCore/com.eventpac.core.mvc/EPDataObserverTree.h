//
//  EPDataObserverTree.h
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPDataObserver.h"
#import "IFRegExp.h"

@interface EPDataObserverTreeRecord : NSObject

@property (nonatomic, strong) NSString *dataPath;
@property (nonatomic, strong) id<EPDataObserver> observer;

- (id)initWithDataPath:(NSString *)dataPath observer:(id<EPDataObserver>)observer;

@end

@interface EPDataObserverTreeNode : NSObject

@property (nonatomic, strong) NSDictionary *children;
@property (nonatomic, strong) NSArray *observers;
@property (nonatomic, strong) NSArray *descendants;

- (void)remove:(id<EPDataObserver>)observer;
- (void)add:(id<EPDataObserver>)observer forPath:(NSString *)path isDescendant:(BOOL)isDescendant;
- (EPDataObserverTreeNode *)getOrCreateChildForName:(NSString *)name;

@end

@interface EPDataObserverTree : NSObject {
    NSString *pathSeparator;
    EPDataObserverTreeNode *root;
}

- (id)initWithPathSeparator:(NSString *)separator;
- (void)addDataObserver:(id<EPDataObserver>)observer forPath:(NSString *)path;
- (NSArray *)getDataObserversForPath:(NSString *)path;
- (NSArray *)getAllDataObservers;
- (void)removeDataObserver:(id<EPDataObserver>)observer;

@end
