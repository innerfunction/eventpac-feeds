//
//  EPDataSource.h
//  EPCore
//
//  Created by Julian Goacher on 28/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPComponent.h"
#import "EPDSResultAdapter.h"
#import "EPDBController.h"

@interface EPDataSource : NSObject <EPComponent> {
    NSString *sql;
    NSArray *argNames;
    id<EPDSResultAdapter> resultAdapter;
}

@property (nonatomic, strong) NSArray *dependencies;

- (id)readDataWithController:(EPDBController *)controller params:(NSDictionary *)params;

@end
