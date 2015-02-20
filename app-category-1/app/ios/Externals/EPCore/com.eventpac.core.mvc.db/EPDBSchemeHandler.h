//
//  EPDBSchemeHandler.h
//  EPCore
//
//  Created by Julian Goacher on 27/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFSchemeHandler.h"
#import "EPUpdateableSchemeHandler.h"
#import "EPComponent.h"
#import "EPDBController.h"

@interface EPDBSchemeHandler : NSObject <IFSchemeHandler, EPUpdateableSchemeHandler, EPComponent> {
    EPDBController *dbController;
}

- (id)initWithDBController:(EPDBController *)dbController;

@end
