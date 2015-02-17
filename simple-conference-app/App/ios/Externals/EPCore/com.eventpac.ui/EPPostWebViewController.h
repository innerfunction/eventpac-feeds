//
//  EPPostWebViewController.h
//  EPCore
//
//  Created by Julian Goacher on 20/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPWebViewController.h"
#import "EPFavouriteBarButtonItem.h"

@interface EPPostWebViewController : EPWebViewController {
    EPFavouriteBarButtonItem *favouriteButton;
}

@property (nonatomic, strong) NSString *postID;

@end
