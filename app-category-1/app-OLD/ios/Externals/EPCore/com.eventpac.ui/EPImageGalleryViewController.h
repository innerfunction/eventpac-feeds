//
//  EPPhotoGalleryViewController.h
//  EventPacComponents
//
//  Created by Julian Goacher on 12/04/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPConfiguration.h"
#import "EPComponent.h"
#import "FGalleryViewController.h"

@interface EPImageGalleryViewController : FGalleryViewController <EPComponent, FGalleryViewControllerDelegate> {
    EPConfiguration *configuration;
    NSArray *images;
}

@end
