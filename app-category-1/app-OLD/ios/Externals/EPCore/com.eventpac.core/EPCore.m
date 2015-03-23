//
//  EPCore.m
//  EPCore
//
//  Created by Julian Goacher on 06/02/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPCore.h"
#import "IFCompoundURI.h"
#import "IFCore.h"
#import "IFJSONData.h"
#import "EPGlobalsSchemeHandler.h"
#import "EPI18nMap.h"
#import "IFTypeConversions.h"
#import "IFStringTemplate.h"
#import "NSString+IF.h"
#import "UIViewController+EP.h"

static const int ddLogLevel = IFCoreLogLevel;

@interface EPCore ()

- (void)configureWith:(EPConfiguration *)config;
- (id)makeDefaultGlobalModelValues;
- (void)setDefaultLocalSettings;

@end

@implementation EPCore

@synthesize globalValues, configuration, resolver, types, activeView;

- (id)init {
    self = [super init];
    if (self) {
        self.uri = [[IFCompoundURI alloc] initWithScheme:@"s" name:@"EPCore"];
    }
    return self;
}

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [self init];
    if (self) {
        [self configureWith:config];
    }
    return self;
}

- (void)configureWith:(EPConfiguration *)config {
    // Set the resource data (i.e. superclass resource)
    self.data = config;

    self.configuration = config;
    
    mode = [config getValueAsString:@"mode" defaultValue:@"LIVE"];
    NSLog(@"EPCore: Configuration mode is '%@'", mode);
    
    // Setup EPCore properties.
    if (!self.resolver) {
        self.resolver = [[IFStandardURIResolver alloc] init];
    }
    
    // Setup global namespace & globals: URI scheme.
    self.globalValues = [self makeDefaultGlobalModelValues];
    
    // Setup template context.
    configuration.context = self.globalValues;
    
    self.types = [configuration getValueAsConfiguration:@"types"];
    
    self.resolver.parentResource = self;

    [self setDefaultLocalSettings];
    
    services = [[NSMutableArray alloc] init];
    NSMutableDictionary *servicesByName = [[NSMutableDictionary alloc] init];

    // Setup MVC controller.
    self.mvc = [[EPController alloc] initWithConfiguration:configuration];
    _mvc.resolver = resolver;
    [services addObject:_mvc];
    [servicesByName setObject:_mvc forKey:@"mvc"];

    // Setup services.
    if ([configuration getValueType:@"services"] == EPValueTypeList) {
        NSArray *servicesConfig = [configuration getValueAsConfigurationList:@"services"];
        NSInteger i = 0;
        for (EPConfiguration *serviceConfig in servicesConfig) {
            NSString *serviceName = [serviceConfig getValueAsString:@"name"];
            if (serviceName) {
                id<EPComponent> service = [self makeComponentWithConfiguration:serviceConfig identifier:serviceName];
                if ([service conformsToProtocol:@protocol(EPService)]) {
                    [services addObject:service];
                    [servicesByName setObject:service forKey:serviceName];
                }
            }
            else {
                DDLogWarn(@"EPCore: No name provided for service at position %ld, skipping instantiation", (long)i);
            }
            i++;
        }
    }
    else {
        DDLogError(@"EPCore: 'services' configuration must be a list");
    }

    self.servicesByName = [NSDictionary dictionaryWithDictionary:servicesByName];
    [globalValues setObject:servicesByName forKey:@"services"];
    
    // Add additional schemes to the resolver/dispatcher.
    EPConfiguration *dispatcherConfig = [configuration getValueAsConfiguration:@"dispatcher.schemes"];
    for (NSString *schemeName in [dispatcherConfig getValueNames]) {
        EPConfiguration *schemeConfig = [dispatcherConfig getValueAsConfiguration:schemeName];
        id<EPComponent> schemeHandler = [self makeComponentWithConfiguration:schemeConfig identifier:schemeName];
        if (schemeHandler) {
            [resolver addHandler:(id<IFSchemeHandler>)schemeHandler forScheme:schemeName];
            if ([schemeHandler conformsToProtocol:@protocol(EPService)]) {
                [services addObject:schemeHandler];
                [servicesByName setObject:schemeHandler forKey:[NSString stringWithFormat:@"%@:", schemeName]];
            }
        }
    }

    [_mvc setGlobalValue:servicesByName forName:@"services"];
}

- (id)makeDefaultGlobalModelValues {
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    NSDictionary *platformValues = @{
        @"name": EPPlatform(),
        @"dispay": EPDisplay(),
        @"default": @"ios2x",
        @"full": @"ios2x" // TODO: Review need for this, added because subscription config for LaVuelta
                          // references {platform.full} in zip path.
    };
    [values setObject:platformValues forKey:@"platform"];

    [values setObject:mode forKey:@"mode"];
    
    NSLocale *locale = [NSLocale currentLocale];
    NSString *lang = nil;
    DDLogInfo(@"Current locale is %@", locale.localeIdentifier);
    
    // The 'assetLocales' setting can be used to declare a list of the locales that app assets are
    // available in. If the platform's default locale (above) isn't on this list then the code below
    // will attempt to find a supported locale that uses the same language; if no match is found then
    // the first locale on the list is used as the default.
    if ([configuration hasValue:@"assetLocales"]) {
        NSArray *assetLocales = [configuration getValue:@"assetLocales"];
        if ([assetLocales count] > 0 && ![assetLocales containsObject:locale.localeIdentifier]) {
            // Attempt to find a matching locale.
            // Always assigns the first item on the list (as the default option); if a later
            // item has a matching language then that is assigned and the loop is exited.
            NSString *lang = [locale objectForKey:NSLocaleLanguageCode];
            BOOL langMatch = NO, assignDefault;
            for (NSInteger i = 0; i < [assetLocales count] && !langMatch; i++) {
                NSString *assetLocale = [assetLocales objectAtIndex:0];
                NSArray *localeParts = [assetLocale split:@"_"];
                assignDefault = (i == 0);
                langMatch = [[localeParts objectAtIndex:0] isEqualToString:lang];
                if (assignDefault||langMatch) {
                    locale = [NSLocale localeWithLocaleIdentifier:assetLocale];
                }
            }
        }
        // Handle the case where the user's selected language is different from the locale.
        // See http://stackoverflow.com/questions/3910244/getting-current-device-language-in-ios
        NSString *preferredLang = [[NSLocale preferredLanguages] objectAtIndex:0];
        if (![[locale objectForKey:NSLocaleLanguageCode] isEqualToString:preferredLang]) {
            // Use the user's selected language if listed in assetLocales.
            for (NSString *assetLocale in assetLocales) {
                NSArray *localeParts = [assetLocale split:@"_"];
                if ([[localeParts objectAtIndex:0] isEqualToString:preferredLang]) {
                    lang = preferredLang;
                    break;
                }
            }
        }
    }
    
    if (!lang) {
        // If the user's preferred language hasn't been selected, then use the current locale's.
        lang = [locale objectForKey:NSLocaleLanguageCode];
    }
    DDLogInfo(@"Using language %@", lang);
    
    NSDictionary *localeValues = @{
        @"id": [locale objectForKey:NSLocaleIdentifier],
        @"lang": lang,
        @"variant": [locale objectForKey:NSLocaleCountryCode]
                                   
    };
    [values setObject:localeValues forKey:@"locale"];
    [values setObject:[EPI18nMap instance] forKey:@"i18n"];
    
    return values;
}

- (id<EPComponent>)makeComponentWithConfiguration:(EPConfiguration *)definition identifier:(NSString *)identifier {
    definition = [definition normalize];
    NSString *type = [definition getValueAsString:@"type"];
    id<EPComponent> result = nil;
    if (type) {
        NSString *className = [types getValueAsString:type];
        if (className) {
            result = [self makeComponentWithConfiguration:definition componentClass:className identifier:identifier];
        }
        else {
            DDLogWarn(@"EPCore - make '%@': No class name found for type (%@)", identifier, type);
        }
    }
    else {
        DDLogWarn(@"EPCore - make '%@': Component configuration missing 'type' property", identifier );
    }
    return result;
}

- (id<EPComponent>)makeComponentWithConfiguration:(EPConfiguration *)definition componentClass:(NSString *)className identifier:(NSString *)identifier {
    id<EPComponent> result = nil;
    id componentClass = [NSClassFromString(className) alloc];
    // Check that we have a component class.
    if (!componentClass) {
        DDLogWarn(@"EPCore - make '%@': Class %@ not found", identifier, className);
    }
    // If the class is a component factory...
    if ([componentClass conformsToProtocol:@protocol(EPComponentFactory)]) {
        // ...then delegate component creation to the factory.
        result = [(id<EPComponentFactory>)componentClass componentWithConfiguration:definition];
    }
    // Else if class is a component class...
    else if ([componentClass conformsToProtocol:@protocol(EPComponent)]) {
        // ...then instantiate the component.
        result = [(id<EPComponent>)componentClass initWithConfiguration:definition];
    }
    // ...else invalid component class.
    else {
        DDLogWarn(@"EPCore - make '%@': Class %@ doesn't conform to EPComponent or EPComponentFactory", identifier, className);
    }
    // If we have a result with a 'core' property, then set it to this instance.
    if (result && [result respondsToSelector:@selector(setCore:)]) {
        result.core = self;
    }
    return result;
}

- (UIImage *)resolveImage:(NSString *)ref {
    return [self resolveImage:ref context:self];
}

- (UIImage *)resolveImage:(NSString *)ref context:(IFResource *)resource {
    ref = [IFStringTemplate render:ref context:self.globalValues];
    UIImage *image = nil;
    if ([ref hasPrefix:@"@"]) {
        NSString* uri = [ref substringFromIndex:1];
        IFResource* rsc = [resolver resolveURIFromString:uri context:resource];
        if (rsc) {
            image = [rsc asImage];
        }
    }
    else {
        image = [IFTypeConversions asImage:ref];
    }
    return image;
}

// Test whether a URI is an Eventpac URI.
- (BOOL)isEPURIScheme:(NSString *)schemeName {
    return [resolver hasHandlerForURIScheme:schemeName];
}

- (void)addDataObserver:(id<EPDataObserver>)observer forConfiguration:(EPConfiguration *)config {
    if ([config hasValue:@"observes"]) {
        NSString *observes = [config getValueAsString:@"observes"];
        EPDataModel *globalModel = self.mvc.globalModel;
        [globalModel addDataObserver:observer forPath:observes];
        if ([observer respondsToSelector:@selector(setObserves:)]) {
            [observer setObserves:observes];
        }
    }
}

- (void)removeDataObserver:(id<EPDataObserver>)observer {
    EPDataModel *globalModel = self.mvc.globalModel;
    [globalModel removeDataObserver:observer];
}

- (void)startService {
    for (id<EPService> service in services) {
        [service startService];
    }
}

- (void)stopService {
    for (id<EPService> service in services) {
        [service stopService];
    }
}

- (UIViewController *)getRootView {
    id rootView = [configuration getValue:@"rootView"];
    if (!rootView) {
        [NSException raise:@"EPCoreInvalidRootView" format:@"Root view is nil"];
    }
    if (![rootView isKindOfClass:[UIViewController class]]) {
        [NSException raise:@"EPCoreInvalidRootView" format:@"Invalid root view of class %@", [rootView class]];
    }
    // Wrap the root view in a navigation controller if a tabset or navigation view isn't being used.
    UIViewController *rootVC = (UIViewController *)rootView;
    if (!([rootVC isKindOfClass:[UITabBarController class]] || [rootVC isKindOfClass:[UINavigationController class]])) {
        rootVC = [[UINavigationController alloc] initWithRootViewController:rootVC];
    }
    return rootVC;
}

- (EPViewFactoryService *)getViewFactory {
    EPViewFactoryService *viewFactory = (EPViewFactoryService *)[self.servicesByName valueForKey:@"viewFactory"];
    if( !viewFactory ) {
        DDLogWarn(@"EPCore - View factory service not found (service 'viewFactory')");
    }
    return viewFactory;
}

- (id)handleEPEvent:(EPEvent *)event {
    id result = [EPEvent notHandledResult];
    // If the event name starts with service/ then try dispatching it to a named service.
    if ([event.name hasPrefix:@"service/"]) {
        NSString *serviceName = [event.name substringFromIndex:8];
        id service = [self.servicesByName objectForKey:serviceName];
        if ([service conformsToProtocol:@protocol(EPEventHandler)]) {
            result = [(id<EPEventHandler>)service handleEPEvent:event];
        }
    }
    return [EPEvent isNotHandled:result] ? nil : result;
}

- (id)dispatchAction:(NSString *)action {
    id result = nil;
    if ([self.activeView conformsToProtocol:@protocol(EPEventHandler)]) {
        result = [self dispatchAction:action toHandler:(id<EPEventHandler>)self.activeView];
    }
    return result;
}

- (id)dispatchAction:(NSString *)action toHandler:(id<EPEventHandler>)handler {
    id result = nil;
    if (handler) {
        action = [IFStringTemplate render:action context:self.globalValues];
        NSString *url = [action hasPrefix:@"event:"] ? action : [NSString stringWithFormat:@"event:%@", action];
        id resource = [self.resolver resolveURIFromString:url];
        if ([resource isKindOfClass:[EPEvent class]]) {
            result = [handler handleEPEvent:(EPEvent *)resource];
        }
    }
    return result;
}

- (id)dispatchURI:(NSString *)uri toHandler:(id<EPEventHandler>)handler {
    return [uri hasPrefix:@"event:"] ? [self dispatchAction:uri toHandler:handler] : nil;
}

- (void)setDefaultLocalSettings {
    NSDictionary *settings = [configuration getValue:@"settings"];
    for (NSString *key in [settings keyEnumerator]) {
        if ([LocalStorage valueForKey:key] == nil || ForceResetDefaultSettings) {
            [LocalStorage setObject:[settings valueForKey:key] forKey:key];
        }
    }
}

- (void)showToast:(NSString *)toast {
    toast = NSLocalizedString(toast, @"");
    [self.activeView showToast:toast];
}

// Singleton instance of this class.
// The class isn't a strict singleton (the initializers are public), but in normal usage the static setupWithConfiguration: method
// should be used, and this will instantiate the singleton instance assigned to this variable.
static EPCore *instance;

+ (void)initialize {
    // Configure logging.
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    instance = [[EPCore alloc] init];
}

+ (EPCore *)setupWithConfiguration:(id)configuration {
    return [EPCore setupWithConfiguration:configuration mainBundlePath:MainBundlePath];
}

+ (EPCore *)setupWithConfiguration:(id)configuration mainBundlePath:(NSString *)mainBundlePath {
    if ([configuration isKindOfClass:[EPConfiguration class]]) {
        [instance configureWith:(EPConfiguration *)configuration];
    }
    else {
        EPConfiguration *config;
        instance.resolver = [[IFStandardURIResolver alloc] initWithMainBundlePath:mainBundlePath];
        IFCompoundURI *uri = nil;
        if ([configuration isKindOfClass:[IFCompoundURI class]]) {
            uri = (IFCompoundURI *)configuration;
        }
        else if ([configuration isKindOfClass:[NSString class]]) {
            NSError *error = nil;
            uri = [IFCompoundURI parse:(NSString *)configuration error:&error];
            if (error) {
                [NSException raise:@"EPCoreInvalidConfigurationURI" format:@"Invalid URI: %@ code: %ld message: %@", configuration, (long)error.code, [error.userInfo valueForKey:@"message"]];
            }
        }
        if (uri) {
            DDLogCInfo(@"Initializing EPCore with URI %@", uri );
            IFResource *resource = [instance.resolver resolveURI:uri context:instance];
            config = [[EPConfiguration alloc] initWithResource:resource];
        }
        else {
            DDLogCInfo(@"Initializing EPCore with data...");
            config = [[EPConfiguration alloc] initWithData:configuration resource:instance];
        }
        [instance configureWith:config];
    }
    return instance;
}


+ (EPCore *)getCore {
    return instance;
}

+ (EPCore *)startWithConfiguration:(id)configuration window:(UIWindow *)window {
    EPCore *core = [EPCore setupWithConfiguration:configuration];
    [core startService];
    window.rootViewController = [core getRootView];
    window.backgroundColor = [UIColor whiteColor]; // TODO: Make this configurable
    return core;
}

@end
