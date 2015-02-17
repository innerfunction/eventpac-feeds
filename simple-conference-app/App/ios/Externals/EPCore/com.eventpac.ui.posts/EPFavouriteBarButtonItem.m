//
//  EPFavouriteBarButtonItem.m
//  EPCore
//
//  Created by Julian Goacher on 10/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPFavouriteBarButtonItem.h"
#import "EPComponent.h"
#import "EPCore.h"

@implementation EPFavouriteBarButtonItem

- (id)initWithConfiguration:(EPConfiguration *)config {
    core = [EPCore getCore];
    onImage = [config getValueAsImage:@"onImage"];
    offImage = [config getValueAsImage:@"offImage"];
    notificationService = (EPNotificationService *)[core.servicesByName valueForKey:@"notifications"];
    self = [super initWithImage:offImage style:UIBarButtonItemStylePlain target:self action:@selector(toggleFavourite)];
    if (self) {
        onMessage = [config getValueAsLocalizedString:@"onMessage"];
        offMessage = [config getValueAsLocalizedString:@"offMessage"];
    }
    return self;
}

- (void)setPostID:(NSString *)postID {
    _postID = postID;
    BOOL isFavourite = [notificationService favouriteStatusForPost:postID];
    self.image = isFavourite ? onImage : offImage;
}

- (BOOL)toggleFavourite {
    BOOL isFavourite = [notificationService togglePostFavouriteStatus:self.postID];
    if (isFavourite) {
        self.image = onImage;
        if (onMessage) {
            [core showToast:onMessage];
        }
    }
    else {
        self.image = offImage;
        if (offMessage) {
            [core showToast:offMessage];
        }
    }    
    return isFavourite;
}

@end
