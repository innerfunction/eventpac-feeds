//
//  EPAliasSchemeHandler.h
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFSchemeHandler.h"
#import "IFURIResolver.h"
#import "EPUpdateableSchemeHandler.h"
#import "EPJSONModel.h"

@interface EPAliasSchemeHandler : NSObject <IFSchemeHandler, EPUpdateableSchemeHandler> {
    id<IFURIResolver> resolver;
    EPJSONModel *aliases;
}

- (id)initWithResolver:(id<IFURIResolver>)resolver aliases:(NSDictionary *)aliases;
- (IFCompoundURI *)resolveAliasToURI:(NSString *)alias;

@end
