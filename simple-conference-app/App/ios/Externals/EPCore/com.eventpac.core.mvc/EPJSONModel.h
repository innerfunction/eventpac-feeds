//
//  EPJSONModel.h
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPDataModel.h"
#import "EPComponent.h"
#import "EPJSONData.h"

@interface EPJSONModel : EPDataModel <EPComponent> {
    EPJSONData *data;
}

- (id)initWithData:(NSDictionary *)data;
- (void)setRootWithData:(NSDictionary *)data;
- (void)setRootWithConfiguration:(EPConfiguration *)configuration;
- (void)removeValueAtPath:(NSString *)path;

// TODO: Create list model

@end
