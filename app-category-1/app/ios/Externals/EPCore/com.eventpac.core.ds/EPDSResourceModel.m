//
//  EPDSResourceModel.m
//  EPCore
//
//  Created by Julian Goacher on 01/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPDSResourceModel.h"
#import "EPDataSource.h"

@interface EPDSResourceObserver : NSObject <IFResourceObserver> {
    NSArray *dependencyURIs;
    id<IFResourceObserver> observer;
    EPController *controller;
}

- (id)initWithDataSource:(EPDataSource *)_ds observer:(id<IFResourceObserver>)_observer controller:(EPController *)_controller;
- (void)removeResourceObservers;

@end

@interface EPDSDataObserver : NSObject <EPDataObserver> {
    id<IFResourceObserver> observer;
    EPDSResourceObserver *dsObserver;
}

- (id)initWithResourceObserver:(id<IFResourceObserver>)_observer dsObserver:(EPDSResourceObserver *)_dsObserver;

@end

@implementation EPDSResourceModel

- (id)initWithSchemeHandler:(EPDSSchemeHandler *)_handler controller:(EPController *)_controller {
    self = [super init];
    if (self) {
        dsSchemeHandler = _handler;
        controller = _controller;
    }
    return self;
}

- (id<EPDataObserver>)createDataObserverForResourceObserver:(id<IFResourceObserver>)observer uri:(IFCompoundURI *)uri {
    EPDataSource *ds = [dsSchemeHandler.dataSources objectForKey:uri.name];
    EPDSResourceObserver *dsObserver = [[EPDSResourceObserver alloc] initWithDataSource:ds observer:observer controller:controller];
    return [[EPDSDataObserver alloc] initWithResourceObserver:observer dsObserver:dsObserver];
}

@end

@implementation EPDSResourceObserver

- (id)initWithDataSource:(EPDataSource *)_ds observer:(id<IFResourceObserver>)_observer controller:(EPController *)_controller {
    self = [super init];
    if (self) {
        NSMutableArray *uris = [[NSMutableArray alloc] initWithCapacity:[_ds.dependencies count]];
        for (NSString *table in _ds.dependencies) {
            IFCompoundURI *uri = [[IFCompoundURI alloc] initWithScheme:@"db" name:table];
            [_controller addResourceObserver:self forURI:uri];
            [uris addObject:uri];
        }
        dependencyURIs = uris;
        observer = _observer;
        controller = _controller;
    }
    return self;
}

- (void)resourceUpdated:(NSString *)name {
    [observer resourceUpdated:name];
}

- (void)removeResourceObservers {
    for (IFCompoundURI *uri in dependencyURIs) {
        [controller removeResourceObserver:self forURI:uri];
    }
}

@end

@implementation EPDSDataObserver

- (id)initWithResourceObserver:(id<IFResourceObserver>)_observer dsObserver:(EPDSResourceObserver *)_dsObserver {
    self = [super init];
    if (self) {
        observer = _observer;
        dsObserver = _dsObserver;
    }
    return self;
}

- (void)notifyDataChangedAtPath:(NSString *)path inModel:(EPModel *)model {
    [observer resourceUpdated:path];
}

- (void)destroyDataObserver {
    [dsObserver removeResourceObservers];
}

@end