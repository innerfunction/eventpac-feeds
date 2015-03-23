//
//  EPCacheSchemeHandler.h
//  EPCore
//
//  Created by Julian Goacher on 28/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPComponent.h"
#import "IFFileBasedSchemeHandler.h"
#import "EPUpdateableSchemeHandler.h"

@interface EPCacheSchemeHandler : IFFileBasedSchemeHandler <EPComponent, EPUpdateableSchemeHandler>

@end
