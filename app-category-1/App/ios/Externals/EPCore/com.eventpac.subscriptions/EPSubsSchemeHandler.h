//
//  EPSubsSchemeHandler.h
//  EPCore
//
//  Created by Julian Goacher on 17/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "IFFileBasedSchemeHandler.h"
#import "EPComponent.h"
#import "EPUpdateableSchemeHandler.h"
#import "EPSubscriptionService.h"

@interface EPSubsSchemeHandler : IFFileBasedSchemeHandler <EPComponent, EPUpdateableSchemeHandler> {
    EPSubscriptionService *subscriptionService;
}

@end
