//
//  EPController.m
//  EPCore
//
//  Created by Julian Goacher on 22/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPController.h"
#import "EPDBController.h"
#import "EPUpdateableSchemeHandler.h"
#import "EPGlobalsSchemeHandler.h"
#import "EPDBSchemeHandler.h"
#import "NSDictionary+IF.h"

@implementation EPController

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        configuration = config;
        resourceModelsByScheme = [NSDictionary dictionary];
        
        self.globalModel = [[EPJSONModel alloc] initWithConfiguration:config];
        
        self.dbController = [[EPDBController alloc] initWithConfiguration:config];
    }
    return self;
}

- (void)setResolver:(IFStandardURIResolver *)resolver {
    _resolver = resolver;
    
    // Add globals: and db: schemes.
    EPGlobalsSchemeHandler *globalsSchemeHandler = [[EPGlobalsSchemeHandler alloc] initWithGlobalModel:self.globalModel];
    [self.resolver addHandler:globalsSchemeHandler forScheme:@"globals"];
    
    EPDBSchemeHandler *dbSchemeHandler = [[EPDBSchemeHandler alloc] initWithDBController:self.dbController];
    [self.resolver addHandler:dbSchemeHandler forScheme:@"db"];
}
- (void)setGlobalValue:(id)value forName:(NSString *)name {
    [self.globalModel setValue:value forPath:name];
}

- (void)notifyResourceObserversOfScheme:(NSString *)scheme path:(NSString *)path {
    EPResourceModel *model = [resourceModelsByScheme objectForKey:scheme];
    if (model) {
        [model notifyDataObserversForPath:path];
    }
}

- (void)notifyResourceObserversOfURI:(IFCompoundURI *)uri {
    EPResourceModel *model = [resourceModelsByScheme objectForKey:uri.scheme];
    if (model) {
        [model notifyDataObserversForURI:uri];
    }
}

- (BOOL)addResourceObserver:(id<IFResourceObserver>)observer forResource:(IFResource *)resource {
    return [self addResourceObserver:observer forURI:resource.uri];
}

- (BOOL)addResourceObserver:(id<IFResourceObserver>)observer forURI:(IFCompoundURI *)uri {
    EPResourceModel *model = [resourceModelsByScheme objectForKey:uri.scheme];
    if (model) {
        [model addResourceObserver:observer forURI:uri];
    }
    return !!model;
}

- (void)removeResourceObserver:(id<IFResourceObserver>)observer forResource:(IFResource *)resource {
    [self removeResourceObserver:observer forURI:resource.uri];
}

- (void)removeResourceObserver:(id<IFResourceObserver>)observer forURI:(IFCompoundURI *)uri {
    EPResourceModel *model = [resourceModelsByScheme objectForKey:uri.scheme];
    if (model) {
        [model removeResourceObserver:observer];
    }
}

- (void)startService {
    // Resolve resource models for updateable URI schemes.
    for (NSString *scheme in [self.resolver getURISchemeNames]) {
        id<IFSchemeHandler> schemeHandler = [self.resolver getHandlerForURIScheme:scheme];
        if ([schemeHandler conformsToProtocol:@protocol(EPUpdateableSchemeHandler)]) {
            EPResourceModel *resourceModel = [(id<EPUpdateableSchemeHandler>)schemeHandler getResourceModel:self];
            resourceModelsByScheme = [resourceModelsByScheme dictionaryWithAddedObject:resourceModel forKey:scheme];
        }
    }
    // Start the database service.
    [self.dbController startService];
    // Initialize global data.
    EPConfiguration *dataConfig = [configuration getValueAsConfiguration:@"globals"];
    for (NSString *name in [dataConfig getValueNames]) {
        IFResource *resource = [dataConfig getValueAsResource:name];
        id value = [resource asDefault];
        if (value) {
            [self setGlobalValue:[resource asDefault] forName:name];
            if (resource.updateable) {
                EPControllerGlobalValueResourceObserver *observer = [[EPControllerGlobalValueResourceObserver alloc] initWithController:self
                                                                                                                               resource:resource
                                                                                                                               dataName:name];
                [self addResourceObserver:observer forResource:resource];
            }
        }
    }
}

- (void)stopService {
    [self.dbController stopService];
}

@end

@implementation EPControllerGlobalValueResourceObserver

- (id)initWithController:(EPController *)controller resource:(IFResource *)resource dataName:(NSString *)dataName {
    self = [super init];
    if (self) {
        self.controller = controller;
        self.resource = resource;
        self.dataName = dataName;
    }
    return self;
}

- (void)resourceUpdated:(NSString *)name {
    self.resource = [self.resource refresh];
    [self.controller setGlobalValue:[self.resource asDefault] forName:self.dataName];
}

@end
