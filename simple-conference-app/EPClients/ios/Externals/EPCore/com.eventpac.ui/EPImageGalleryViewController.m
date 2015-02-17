//
//  EPPhotoGalleryViewController.m
//  EventPacComponents
//
//  Created by Julian Goacher on 12/04/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "EPImageGalleryViewController.h"
#import "IFFileResource.h"
#import "UIViewController+EP.h"

@implementation EPImageGalleryViewController

- (id)initWithConfiguration:(EPConfiguration*)config {
    self = [super initWithPhotoSource:self];
    if (self) {
        configuration = config;
        if ([configuration getValueType:@"images"] == EPValueTypeList) {
            images = [configuration getValueAsConfigurationList:@"images"];
        }
        self.beginsInThumbnailView = YES;
        self.hideTitle = NO;
        [self applyStandardConfiguration:configuration];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyStandardOnLoadConfiguration:configuration];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self applyStandardOnAppearConfiguration:configuration];

    if ([images count] < 2) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    // TODO: Toolbar isn't currently used, so hide it. May in future allow configuration options
    // which use the toolbar.
    self.toolBar.hidden = YES;
    // NOTE: This is a temporary change to force the title to the configured value.
    self.navigationItem.title = [configuration getValueAsString:@"title" defaultValue:@""];
}

#pragma mark - fgallery delegate

- (int)numberOfPhotosForPhotoGallery:(FGalleryViewController*)gallery {
    return (int)[images count];
}

- (FGalleryPhotoSourceType)photoGallery:(FGalleryViewController*)gallery sourceTypeForPhotoAtIndex:(NSUInteger)index {
    //return FGalleryPhotoSourceTypeLocal;
    return FGalleryPhotoSourceTypeNetwork;
}

// Resolve an image URL from either a string or URI reference.
NSURL *resolveImageURL(EPConfiguration *imageConfig, NSString *propertyName) {
    NSURL *imageURL = nil;
    NSString *url = [imageConfig getValueAsString:propertyName];
    if ([url hasPrefix:@"http"]) {
        // Image is specified as an external URL.
        imageURL = [imageConfig getValueAsURL:propertyName];
    }
    else {
        // Convert a local image reference to a URL. This will only work if the image can be resolved as a file resource.
        IFResource *rsc = [imageConfig getValueAsResource:propertyName];
        if ([rsc isKindOfClass:[IFFileResource class]]) {
            imageURL = [(IFFileResource *)rsc externalURL];
        }
    }
    return imageURL;
}

- (NSString*)photoGallery:(FGalleryViewController *)gallery urlForPhotoSize:(FGalleryPhotoSize)size atIndex:(NSUInteger)index {
//- (NSString*)photoGallery:(FGalleryViewController*)gallery filePathForPhotoSize:(FGalleryPhotoSize)size atIndex:(NSUInteger)index {
    // Problem with returning a path value is that FGallery assumes it is relative to the main bundle root, whilst in fact it is
    // an absolute path. Use a file: URL for now.
    EPConfiguration *imageConfig = [images objectAtIndex:index];
    NSURL *imageURL = nil;
    if (size == FGalleryPhotoSizeThumbnail && [imageConfig hasValue:@"thumbnail"]) {
        imageURL = resolveImageURL(imageConfig, @"thumbnail");
    }
    else if ([imageConfig hasValue:@"image"]) {
        imageURL = resolveImageURL(imageConfig, @"image");
    }
    return [imageURL absoluteString];
}

@end
