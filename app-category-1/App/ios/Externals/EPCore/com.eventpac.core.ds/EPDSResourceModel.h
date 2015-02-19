//
//  EPDSResourceModel.h
//  EPCore
//
//  Created by Julian Goacher on 01/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPResourceModel.h"
#import "EPDSSchemeHandler.h"
#import "EPController.h"

@interface EPDSResourceModel : EPResourceModel {
    EPDSSchemeHandler *dsSchemeHandler;
    EPController *controller;
}

- (id)initWithSchemeHandler:(EPDSSchemeHandler *)_handler controller:(EPController *)_controller;

@end
