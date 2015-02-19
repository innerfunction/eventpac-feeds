//
//  EPViewResource.h
//  EPCore
//
//  Created by Julian Goacher on 03/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "IFResource.h"
#import "EPView.h"

@class EPViewFactoryService;

@interface EPViewResource : IFResource {
    EPConfiguration *configuration;
    EPViewFactoryService *factory;
}

- (id)initWithConfiguration:(EPConfiguration *)config factory:(EPViewFactoryService *)factory uri:(IFCompoundURI *)uri parent:(IFResource *)parent;
- (UIViewController *)asView;

@end
