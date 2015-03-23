//
//  EPGoogleMapViewController.h
//  EPCore
//
//  Created by Julian Goacher on 06/01/2015.
//  Copyright (c) 2015 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPViewController.h"
#import <GoogleMaps/GoogleMaps.h>

@interface EPGoogleMapViewController : EPViewController <GMSMapViewDelegate> {
    EPConfiguration *startCameraPosition;
    NSArray *markers;
    BOOL deviceLocationEnabled;
    GMSMapView *mapView;
}

@end
