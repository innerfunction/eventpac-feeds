//
//  EPCore.h
//  EPCore
//
//  Created by Julian Goacher on 06/02/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPConfiguration.h"
#import "IFResource.h"
#import "EPService.h"
#import "EPViewFactoryService.h"
#import "EPController.h"
#import "EPEvent.h"
#import "EPEventHandler.h"
#import "IFURIResolver.h"

#define EPPlatform()            (@"ios")
#define EPDisplay()             ([UIScreen mainScreen].scale == 2.0 ? @"2x" : @"")
#define IOSVersion()            ([[UIDevice currentDevice] systemVersion])
#define IsIOSVersion(v)         ([IOSVersion() compare:v options:NSNumericSearch] == NSOrderedSame)
#define IsIOSVersionSince(v)    ([IOSVersion() compare:v options:NSNumericSearch] != NSOrderedAscending)
#define IsIOSVersionUpTo(v)     ([IOSVersion() compare:v options:NSNumericSearch] != NSOrderedDescending)
#define IsIOS7                  (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)

// App settings via local storage
#define LocalStorage            ([NSUserDefaults standardUserDefaults])
#define GetStringSetting(name)  ([LocalStorage stringForKey:name])
#define GetNumberSetting(name)  ([LocalStorage doubleForKey:name])
#define GetBooleanSetting(name) ([LocalStorage boolForKey:name])

#define ForceResetDefaultSettings (NO)

// Read a boolean value from a dictionary.
#define ValueAsBoolean(d,name)  ([(NSNumber *)[d valueForKey:name] integerValue] == 1)

// The eventpac core service and root resource.
@interface EPCore : IFResource <EPService, EPEventHandler> {
    // The configuration mode.
    NSString *mode;
    // A list of eventpac services.
    NSMutableArray *services;
}

// A map of global values.
@property (nonatomic, strong) NSMutableDictionary *globalValues;
// An object for resolving URIs.
@property (nonatomic, strong) IFStandardURIResolver *resolver;
// The loaded configuration.
@property (nonatomic, strong) EPConfiguration *configuration;
// A map of type names onto implementing classes.
@property (nonatomic, strong) EPConfiguration *types;
// The MVC controller.
@property (nonatomic, strong) EPController *mvc;
// Dictionary of services keyed by name.
@property (nonatomic, strong) NSDictionary *servicesByName;
// The currently visible view. See UIViewController+EP.
@property (nonatomic, strong) UIViewController *activeView;

// Dispatch an application action to the current active view.
- (id)dispatchAction:(NSString *)action;
// Dispatch an application action to the specified event handler.
- (id)dispatchAction:(NSString *)action toHandler:(id<EPEventHandler>)handler;
// Dispatch a URI.
- (id)dispatchURI:(NSString *)uri toHandler:(id<EPEventHandler>)handler;

// Get the root UI view.
- (UIViewController *)getRootView;

// Get the view factory.
- (EPViewFactoryService *)getViewFactory;
// Test whether a named URI scheme is a supported eventpac scheme.
- (BOOL)isEPURIScheme:(NSString *)schemeName;
// Instantiate and configure a component.
- (id<EPComponent>)makeComponentWithConfiguration:(EPConfiguration *)definition identifier:(NSString *)identifier;
// Instantiate and configure a component with the specified configuration and type class.
- (id<EPComponent>)makeComponentWithConfiguration:(EPConfiguration *)definition componentClass:(NSString *)className identifier:(NSString *)identifier;
// Resolve an image from a string reference.
- (UIImage *)resolveImage:(NSString *)ref;
// Resolve an image from a string reference, against the specified context resource.
- (UIImage *)resolveImage:(NSString *)ref context:(IFResource *)resource;

// Add a data observer for the specified configuration. The configuration should have an "observes" property.
- (void)addDataObserver:(id<EPDataObserver>)observer forConfiguration:(EPConfiguration *)configuration;
// Remove a data observer.
- (void)removeDataObserver:(id<EPDataObserver>)observer;

// Show a toast message on the currently active view.
- (void)showToast:(NSString *)toast;

// Setup the core service with the specified configuration.
// Configuration can be any of the following:
// * An instance of IFValues;
// * An instance of IFTypedValues;
// * An instance of EPConfiguration;
// * A compound URI string;
// * A compound URI instance.
// Returns the configured core service.
+ (EPCore *)setupWithConfiguration:(id)configuration;
// Version of setup which allows the main bundle path to be specified. This is mainly used for unit test purposes.
+ (EPCore *)setupWithConfiguration:(id)configuration mainBundlePath:(NSString *)mainBundlePath;
// Get the core service initialized by the setup method.
+ (EPCore *)getCore;
// Start the core service with the specified configuration and setup the app window.
+ (EPCore *)startWithConfiguration:(id)configuration window:(UIWindow *)window;

@end
