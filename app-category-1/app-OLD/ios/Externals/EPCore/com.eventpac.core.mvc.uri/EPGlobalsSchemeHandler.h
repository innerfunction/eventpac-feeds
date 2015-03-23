//
//  EPGlobalsSchemeHandler.h
//  EPCore
//
//  Created by Julian Goacher on 28/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFSchemeHandler.h"
#import "EPUpdateableSchemeHandler.h"
#import "EPJSONModel.h"

@interface EPGlobalsSchemeHandler : NSObject <IFSchemeHandler, EPUpdateableSchemeHandler> {
    EPJSONModel *globalModel;
}

- (id)initWithGlobalModel:(EPJSONModel *)model;

@end
