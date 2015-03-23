//
//  EPResourceModel.m
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPResourceModel.h"
#import "EPCore.h"

@implementation EPResourceModel

- (id)init {
    return [self initWithPathSeparator:@"/"];
}

- (id)initWithPathSeparator:(NSString *)separator {
    self = [super initWithPathSeparator:separator];
    if (self) {
        resolver = [EPCore getCore].resolver;
        dataObserverLookup = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)getValueForPath:(NSString *)path {
    return [resolver resolveURIFromString:path];
}

- (id)getValueForURI:(IFCompoundURI *)uri {
    return [resolver resolveURI:uri];
}

- (void)addDataObserver:(id<EPDataObserver>)observer forURI:(IFCompoundURI *)uri {
    [self addDataObserver:observer forPath:uri.name];
}

- (void)notifyDataObserversForURI:(IFCompoundURI *)uri {
    [self notifyDataObserversForPath:uri.name];
}

- (void)addResourceObserver:(id<IFResourceObserver>)observer forURI:(IFCompoundURI *)uri {
    id<EPDataObserver> dataObs = [self createDataObserverForResourceObserver:observer uri:uri];
    [self addDataObserver:dataObs forURI:uri];
    // See http://stackoverflow.com/questions/11532306/using-an-object-as-key-for-nsdictionary for technique for using
    // arbitrary objects as dictionary keys.
    [dataObserverLookup setObject:dataObs forKey:[NSValue valueWithNonretainedObject:observer]];
}

- (void)removeResourceObserver:(id<IFResourceObserver>)observer {
    NSValue *key = [NSValue valueWithNonretainedObject:observer];
    id<EPDataObserver> dataObs = [dataObserverLookup objectForKey:key];
    if (dataObs) {
        [self removeDataObserver:dataObs];
        [dataObserverLookup removeObjectForKey:key];
    }
}

- (id<EPDataObserver>)createDataObserverForResourceObserver:(id<IFResourceObserver>)observer uri:(IFCompoundURI *)uri {
    return [[EPResourceModelDataObserver alloc] initWithResourceObserver:observer];
}

@end

@implementation EPResourceModelDataObserver

- (id)initWithResourceObserver:(id<IFResourceObserver>)observer {
    self = [super init];
    if (self) {
        resourceObserver = observer;
    }
    return self;
}

- (void)notifyDataChangedAtPath:(NSString *)path inModel:(EPModel *)model {
    [resourceObserver resourceUpdated:path];
}

- (void)destroyDataObserver {}

@end
