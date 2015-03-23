//
//  EPPostTableCellFavouriteDecorator.m
//  EPCore
//
//  Created by Julian Goacher on 10/10/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPPostTableCellFavouriteDecorator.h"
#import "UIImage+CropScale.h"

#define IndicatorImageTag   (20141010)
#define IndicatorTopX       (10.0f)
#define IndicatorTopY       (0.0f)
#define IndicatorWidth      (20.0f)
#define IndicatorHeight     (20.0f)

@implementation EPPostTableCellFavouriteDecorator

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super init];
    if (self) {
        indicatorImage = [config getValueAsImage:@"indicatorImage"];
        indicatorImage = [indicatorImage scaleToWidth:IndicatorWidth height:IndicatorHeight];
    }
    return self;
}

- (UITableViewCell *)decorateCell:(UITableViewCell *)cell data:(NSDictionary *)data factory:(EPTableViewCellFactory *)factory {
    UIImageView *indicatorView = (UIImageView *)[cell viewWithTag:IndicatorImageTag];
    if (!indicatorView) {
        indicatorView = [[UIImageView alloc] initWithImage:indicatorImage];
        indicatorView.frame = CGRectMake( IndicatorTopX, IndicatorTopY, IndicatorWidth, IndicatorHeight );
        indicatorView.tag = IndicatorImageTag;
        [cell addSubview:indicatorView];
    }
    BOOL isFavourite = ValueAsBoolean(data, @"favourite");
    indicatorView.hidden = !isFavourite;
    return cell;
}

@end
