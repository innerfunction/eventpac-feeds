//
//  EPGoogleMapViewController.m
//  EPCore
//
//  Created by Julian Goacher on 06/01/2015.
//  Copyright (c) 2015 Julian Goacher. All rights reserved.
//

#import "EPGoogleMapViewController.h"
#import "EPCore.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

@implementation EPGoogleMapViewController

@synthesize core;

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super initWithConfiguration:config];
    if (self) {
        startCameraPosition = [config getValueAsConfiguration:@"startPosition"];
        markers = [config getValueAsConfigurationList:@"markers"];
        deviceLocationEnabled = [config getValueAsBoolean:@"deviceLocation" defaultValue:YES];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Initial camera position.
    GMSCameraPosition *camera = nil;
    if (startCameraPosition) {
        NSNumber *lat = [startCameraPosition getValueAsNumber:@"latitude" defaultValue:[NSNumber numberWithInt:0]];
        NSNumber *lon = [startCameraPosition getValueAsNumber:@"longitude" defaultValue:[NSNumber numberWithInt:0]];
        NSNumber *zoom = [startCameraPosition getValueAsNumber:@"zoom" defaultValue:[NSNumber numberWithInt:6]];
        [GMSCameraPosition cameraWithLatitude:[lat floatValue]
                                    longitude:[lon floatValue]
                                         zoom:[zoom intValue]];
    }
    
    // Initialize the map view.
    mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    mapView.myLocationEnabled = deviceLocationEnabled;
    mapView.delegate = self;
    self.view = mapView;

    // Add map markers.
    for (EPConfiguration *markerConfig in markers) {
        GMSMarker *marker = [[GMSMarker alloc] init];
        NSNumber *lat = [markerConfig getValueAsNumber:@"position.latitude" defaultValue:[NSNumber numberWithInt:0]];
        NSNumber *lon = [markerConfig getValueAsNumber:@"position.longitude" defaultValue:[NSNumber numberWithInt:0]];
        marker.position = CLLocationCoordinate2DMake( [lat floatValue], [lon floatValue] );
        marker.title = [markerConfig getValueAsString:@"title"];
        marker.snippet = [markerConfig getValueAsString:@"snippet"];
        marker.map = mapView;
        // Set the marker's config as its user data.
        marker.userData = markerConfig;
    }
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker {
    // Dispatch any action configured on the marker.
    if ([marker.userData isKindOfClass:[EPConfiguration class]]) {
        EPConfiguration *markerConfig = (EPConfiguration *)marker.userData;
        NSString *action = [markerConfig getValueAsString:@"action"];
        if (action) {
            [self.core dispatchAction:action];
        }
    }
}

@end
