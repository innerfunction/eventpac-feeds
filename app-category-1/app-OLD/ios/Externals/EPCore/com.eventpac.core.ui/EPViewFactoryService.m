//
//  EPViewFactory.m
//  EPCore
//
//  Created by Julian Goacher on 03/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPViewFactoryService.h"
#import "EPViewResource.h"
#import "EPCore.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

@implementation EPViewFactoryService

@synthesize core;

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        definitions = config;
    }
    return self;
}

- (void)startService {}

- (void)stopService {}

- (IFResource *)makeViewResourceForURI:(IFCompoundURI *)uri parameters:(NSDictionary *)params parent:(IFResource *)parent {
    EPConfiguration *config = [self getViewConfigurationForURI:uri parameters:params];
    return config ? [[EPViewResource alloc] initWithConfiguration:config factory:self uri:uri parent:parent] : nil;
}

- (UIViewController *)makeViewForURI:(IFCompoundURI *)uri configuration:(EPConfiguration *)config {
    UIViewController *vc = nil;
    id<EPComponent> component = [self.core makeComponentWithConfiguration:config identifier:[uri description]];
    if ([component isKindOfClass:[UIViewController class]]) {
        vc = (UIViewController *)component;
        if ([vc conformsToProtocol:@protocol(EPView)]) {
            ((id<EPView>)vc).viewURI = uri;
        }
    }
    else {
        DDLogWarn(@"EPViewFactory: View from %@ isn't an instance of UIViewController", uri);
    }
    return vc;
}

- (EPConfiguration *)getViewConfigurationForURI:(IFCompoundURI *)uri parameters:(NSDictionary *)params {
    NSString *viewName = uri.name;
    EPConfiguration *viewDefinition = [definitions getValueAsConfiguration:viewName];
    if (viewDefinition) {
        viewDefinition = [viewDefinition extendWithParameters:params];
    }
    else {
        DDLogWarn(@"EPViewFactory: View definition %@ not found", viewName );
    }
    return viewDefinition;
}

@end
