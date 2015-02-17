//
//  EPDataModel.h
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPModel.h"
#import "EPFormatter.h"

@interface EPDataModel : EPModel {
    NSMutableDictionary *implicitViews;
    NSMutableDictionary *formatters;
    id<EPFormatter> defaultFormatter;
}

- (void)setValue:(id)value forPath:(NSString *)path;
- (id<EPFormatter>)getFormatterForPath:(NSString *)path;
- (void)addFormatter:(id<EPFormatter>)formatter forPath:(NSString *)path;

// TODO: add view methods for different UI view types

@end
