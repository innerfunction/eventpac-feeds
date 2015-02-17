//
//  EPMultiRowDSResultAdapter.m
//  EPCore
//
//  Created by Julian Goacher on 29/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPMultiRowDSResultAdapter.h"

@implementation EPMultiRowDSResultAdapter

- (id)mapResult:(NSArray *)result {
    NSMutableArray *rows = [[NSMutableArray alloc] initWithCapacity:[result count]];
    for (NSDictionary *row in result) {
        [rows addObject:[self mapResultRow:row]];
    }
    return rows;
}

@end
