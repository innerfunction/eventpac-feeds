//
//  EPDSSchemeHandler.h
//  EPCore
//
//  Created by Julian Goacher on 01/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFSchemeHandler.h"
#import "EPUpdateableSchemeHandler.h"
#import "EPComponent.h"

@interface EPDSSchemeHandler : NSObject <IFSchemeHandler, EPUpdateableSchemeHandler, EPComponent> {
}

@property (nonatomic, strong) NSDictionary *dataSources;

@end
