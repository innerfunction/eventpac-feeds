//
//  EPDBManifestProcessor.h
//  EPCore
//
//  Created by Julian Goacher on 01/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPConfiguration.h"
#import "EPDBController.h"

// See com.eventpac.subscriptions.DBManifestProcessor class comment for more info on this class.
@interface EPDBManifestProcessor : NSObject {
    EPConfiguration *configuration;
    EPDBController *dbController;
}

- (id)initWithData:(NSDictionary *)data resource:(IFResource *)resource;
- (id)initWithConfiguration:(EPConfiguration *)_configuration;
- (BOOL)process;

@end
