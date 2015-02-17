//
//  EPPostTableViewController.h
//  EPCore
//
//  Created by Julian Goacher on 17/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPTableViewController.h"
#import "EPEventHandler.h"
#import "EPBarButtonItem.h"

@interface EPPostTableViewController : EPTableViewController <EPEventHandler> {
    EPBarButtonItem *leftBarButton;
}

@end
