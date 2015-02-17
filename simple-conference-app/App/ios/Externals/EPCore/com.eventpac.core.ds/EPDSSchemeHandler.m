//
//  EPDSSchemeHandler.m
//  EPCore
//
//  Created by Julian Goacher on 01/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPDSSchemeHandler.h"
#import "EPCore.h"
#import "EPDataSource.h"
#import "EPDSResourceModel.h"
#import "EPDBController.h"

@implementation EPDSSchemeHandler

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        NSMutableDictionary *dataSources = [[NSMutableDictionary alloc] init];
        EPConfiguration *sources = [config getValueAsConfiguration:@"sources"];
        for (NSString *name in [sources getValueNames]) {
            EPDataSource *ds = [[EPDataSource alloc] initWithConfiguration:[sources getValueAsConfiguration:name]];
            [dataSources setObject:ds forKey:name];
        }
        self.dataSources = dataSources;
    }
    return self;
}

- (EPResourceModel *)getResourceModel:(EPController *)controller {
    return [[EPDSResourceModel alloc] initWithSchemeHandler:self controller:controller];
}

- (IFResource *)handle:(IFCompoundURI *)uri parameters:(NSDictionary *)params parent:(IFResource *)parent {
    IFResource *result = nil;
    EPDataSource *ds = [self.dataSources objectForKey:uri.name];
    if (ds) {
        // Resolve data source parameter values.
        NSMutableDictionary *dsParams = [[NSMutableDictionary alloc] initWithCapacity:[params count]];
        for (NSString *name in [params keyEnumerator]) {
            [dsParams setObject:[[params objectForKey:name] description] forKey:name];
        }
        // Resolve data source data
        EPDBController *dbController = [EPCore getCore].mvc.dbController;
        id data = [ds readDataWithController:dbController params:dsParams];
        if (data) {
            result = [[IFResource alloc] initWithData:data uri:uri parent:parent];
            result.updateable = YES;
        }
    }
    return result;
}

@end
