//
//  EPOneRowDSResultAdapter.h
//  EPCore
//
//  Created by Julian Goacher on 15/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPComponent.h"
#import "EPDSResultAdapter.h"
#import "EPDSValueAdapter.h"

@interface EPOneRowDSResultAdapter : NSObject <EPComponent, EPDSResultAdapter> {
    NSDictionary *inputValueFormatters;
    EPDSValueAdapterResult *resultValueAdapter;
}

- (NSDictionary *)mapResultRow:(NSDictionary *)row;

@end
