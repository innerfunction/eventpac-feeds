//
//  EPViewSchemeHandler.h
//  EPCore
//
//  Created by Julian Goacher on 03/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFSchemeHandler.h"
#import "EPComponent.h"
#import "EPViewFactoryService.h"

@interface EPViewSchemeHandler : NSObject <IFSchemeHandler,EPComponent> {
    EPViewFactoryService *viewFactory;
}

@end
