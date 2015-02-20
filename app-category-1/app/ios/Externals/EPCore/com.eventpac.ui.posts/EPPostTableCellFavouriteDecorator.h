//
//  EPPostTableCellFavouriteDecorator.h
//  EPCore
//
//  Created by Julian Goacher on 10/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPComponent.h"
#import "EPTableViewCellFactory.h"

@interface EPPostTableCellFavouriteDecorator : NSObject <EPComponent, EPTableViewCellDecorator> {
    UIImage *indicatorImage;
}

@end
