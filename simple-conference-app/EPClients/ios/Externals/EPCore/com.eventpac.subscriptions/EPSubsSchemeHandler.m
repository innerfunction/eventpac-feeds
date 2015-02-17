//
//  EPSubsSchemeHandler.m
//  EPCore
//
//  Created by Julian Goacher on 17/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPSubsSchemeHandler.h"
#import "EPCore.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

@implementation EPSubsSchemeHandler

- (id)initWithConfiguration:(EPConfiguration *)config {
    subscriptionService = (EPSubscriptionService *)[[EPCore getCore].servicesByName valueForKey:@"subscriptions"];
    if (subscriptionService) {
        self = [super initWithPath:subscriptionService.contentPath];
    }
    else {
        DDLogWarn(@"EPSubsSchemeHandler: Subscription service not found (using name 'subscriptions')");
    }
    return self;
}

- (EPResourceModel *)getResourceModel:(EPController *)controller {
    return [[EPResourceModel alloc] init];
}

- (IFResource *)handle:(IFCompoundURI *)uri parameters:(NSDictionary *)params parent:(IFResource *)parent {
    IFResource* resource = [super handle:uri parameters:params parent:parent];
    if (!resource) {
        // If resource isn't found under the subscription content path, then try looking for it in the initial content path.
        resource = [self resolveURI:uri againstPath:subscriptionService.initialContentPath parent:parent];
    }
    return resource;
}

@end
