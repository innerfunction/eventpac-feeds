//
//  EPDBSchemeHandler.m
//  EPCore
//
//  Created by Julian Goacher on 27/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPDBSchemeHandler.h"
#import "EPCore.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

@implementation EPDBSchemeHandler

@synthesize core;

- (id)initWithConfiguration:(EPConfiguration *)config {
    return [super init];
}

- (id)initWithDBController:(EPDBController *)_dbController {
    self = [super init];
    if (self) {
        dbController = _dbController;
    }
    return self;
}

- (void)setCore:(EPCore *)_core {
    core = _core;
    dbController = core.mvc.dbController;
}

- (EPResourceModel *)getResourceModel:(EPController *)controller {
    return [[EPResourceModel alloc] init];
}

- (IFResource *)handle:(IFCompoundURI *)uri parameters:(NSDictionary *)params parent:(IFResource *)parent {
    IFResource *resource = nil;
    NSArray *names = [uri.name componentsSeparatedByString:@"/"];
    if ([names count] > 1) {
        NSString *table = [names objectAtIndex:0];
        NSString *identifier = [names objectAtIndex:1];
        NSDictionary *data = [dbController readRecordWithID:identifier fromTable:table];
        if (data) {
            resource = [[IFResource alloc] initWithData:data uri:uri parent:parent];
            resource.updateable = YES;
        }
    }
    else {
        DDLogWarn(@"EPDBSchemeHandler: Record ID not specified in URI name '%@'", uri.name);
    }
    return resource;
}

@end
