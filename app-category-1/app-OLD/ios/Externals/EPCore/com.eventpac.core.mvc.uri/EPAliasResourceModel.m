//
//  EPAliasResourceModel.m
//  EPCore
//
//  Created by Julian Goacher on 27/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPAliasResourceModel.h"
#import "EPAliasSchemeHandler.h"

@implementation EPAliasResourceModel

- (id)initWithController:(EPController *)controller handler:(EPAliasSchemeHandler *)handler {
    self = [super init];
    if (self) {
        self.controller = controller;
        self.aliasSchemeHandler = handler;
    }
    return self;
}

- (id<EPDataObserver>)createDataObserverForResourceObserver:(id<IFResourceObserver>)observer uri:(IFCompoundURI *)uri {
    NSString *alias = uri.name;
    EPAliasedResourceObserver *aliasedObserver = [[EPAliasedResourceObserver alloc] initWithAlias:alias observer:observer model:self];
    return [[EPAliasedDataObserver alloc] initWithResourceObserver:aliasedObserver];
}

@end

@implementation EPAliasedResourceObserver

- (id)initWithAlias:(NSString *)_alias observer:(id<IFResourceObserver>)_observer model:(EPAliasResourceModel *)_model {
    self = [super init];
    if (self) {
        alias = _alias;
        observer = _observer;
        model = _model;
        [self updateURI];
    }
    return self;
}

- (void)resourceUpdated:(NSString *)name {
    [observer resourceUpdated:name];
}

- (void)updateURI {
    [self remove];
    uri = [model.aliasSchemeHandler resolveAliasToURI:alias];
    if (uri) {
        [model.controller addResourceObserver:observer forURI:uri];
    }
}

- (void)remove {
    if (uri) {
        [model.controller removeResourceObserver:observer forURI:uri];
    }
}

@end

@implementation EPAliasedDataObserver

- (id)initWithResourceObserver:(id<IFResourceObserver>)observer {
    self = [super init];
    if (self) {
        aliasedResourceObserver = observer;
    }
    return self;
}

- (void)notifyDataChangedAtPath:(NSString *)path inModel:(EPModel *)model {
    [aliasedResourceObserver updateURI];
}

- (void)destroyDataObserver {
    [aliasedResourceObserver remove];
}

@end