//
//  EPCacheSchemeHandler.m
//  EPCore
//
//  Created by Julian Goacher on 28/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPCacheSchemeHandler.h"

@implementation EPCacheSchemeHandler

- (id)initWithConfiguration:(EPConfiguration *)config {
    return [super initWithDirectory:NSCachesDirectory];
}

- (EPResourceModel *)getResourceModel:(EPController *)controller {
    return [[EPResourceModel alloc] init];
}

@end
