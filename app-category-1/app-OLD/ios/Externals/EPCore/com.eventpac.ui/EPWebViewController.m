//
//  EPWebViewController.m
//  EPCore
//
//  Created by Julian Goacher on 04/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPWebViewController.h"
#import "UIViewController+EP.h"
#import "EPCore.h"
#import "EPController.h"
#import "IFFileResource.h"
#import "IFUtils.h"
#import "IFCore.h"
#import "JSONKit.h"

static const int ddLogLevel = IFCoreLogLevel;

@interface EPWebViewController ()

- (void)loadContentFromJSON:(NSString *)json;
- (void)showSpinnerWithCompletion:(void(^)(void))block;
- (void)hideLoadingImage;
- (void)processJSCallQueue;

@end

// TODO: Following are to force the webview and activity indicator to the full size of their subviews -
// Is there a better way to achieve this?

@interface UIWebView (FullScreen)
@end

@implementation UIWebView (FullScreen)

- (void)didMoveToSuperview {
    self.frame = self.superview.frame;
}

@end

@interface UIActivityIndicatorView (FullScreen)

@end

@implementation UIActivityIndicatorView (FullScreen)

- (void)didMoveToSuperview {
    self.frame = self.superview.frame;
}

@end
// -------------------------------------

@implementation EPWebViewController

@synthesize core;

- (id)initWithConfiguration:(EPConfiguration *)config {
    self = [super initWithConfiguration:config];
    if (self) {
        useHTMLTitle = [configuration getValueAsBoolean:@"useHTMLTitle" defaultValue:YES];

        // The ios:containerTitle flag indicates whether the configured web view should control its container's
        // title (by setting the title when the web page content loads). This is useful when the web view is
        // nested within a layout. The value default's to true so in most cases, behaviour is what is expected.
        // The value only needs to be explicitly set to false in cases where a nested web view shouldn't set
        // its container's title.
        shouldSetParentTitle = [configuration getValueAsBoolean:@"ios:containerTitle" defaultValue:YES];
        
        UIImage* loadingImage = [configuration getValueAsImage:@"loadingImage"];
        if (loadingImage) {
            loadingImageView = [[UIImageView alloc] initWithImage:loadingImage];
            loadingImageView.contentMode = UIViewContentModeCenter;
        }
        webViewLoaded = NO;
        jsCallQueue = [[NSMutableArray alloc] init];
        injectJSONFn = [configuration getValueAsString:@"injectJSONFn"];
        loadExternalLinks = [configuration getValueAsBoolean:@"loadExternalURLs" defaultValue:NO];
        if ([configuration getValueType:@"ios:allowExternalURLs"] == EPValueTypeList) {
            allowExternalURLs = (NSArray *)[configuration getValue:@"ios:allowExternalURLs"];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    webView = [[UIWebView alloc] init];
    webView.backgroundColor = [IFUtils colorForHex:[configuration getValueAsString:@"backgroundColor" defaultValue:@"#FFFFFF"]];
    webView.opaque = [configuration getValueAsBoolean:@"ios:opaque" defaultValue:NO];
    webView.scrollView.bounces = [configuration getValueAsBoolean:@"ios:scrollViewBounces" defaultValue:NO];
    webView.autoresizingMask = 1;
    
    [self.view addSubview:webView];
    if (loadingImageView) {
        loadingImageView.frame = webView.frame;
        [self.view addSubview:loadingImageView];
    }
    
    if ([configuration getValueAsBoolean:@"showLoadingSpinner" defaultValue:YES]) {
        spinner = [[UIActivityIndicatorView alloc] initWithFrame:webView.frame];
        spinner.hidden = YES;
        [self.view addSubview:spinner];
    }
    
#if (WEBVIEW_JAVASCRIPT_BRIDGE_LOGGING_ENABLED)
    [WebViewJavascriptBridge enableLogging];
#endif
    
    bridge = [WebViewJavascriptBridge bridgeForWebView:webView webViewDelegate:self handler:^(id data, WVJBResponseCallback callback) {}];
    
    // Handle a console.log call.
    [bridge registerHandler:@"epConsoleLog" handler:^(id data, WVJBResponseCallback callback) {
        // Note: This implementation looses all values for format strings.
        DDLogInfo(@"[WebView]: %@", (NSString*)data );
    }];
    
    // Handle a JS call to dispatch a URI.
    [bridge registerHandler:@"epDispatchAction" handler:^(id data, WVJBResponseCallback callback) {
        NSString* action = (NSString*)data;
        id result = [self.core dispatchAction:action toHandler:self];
        callback([result description]);
    }];
    
    // Handle a JS call to resolve a URI.
    [bridge registerHandler:@"epResolveURI" handler:^(id data, WVJBResponseCallback callback) {
        NSString* uri = (NSString*)data;
        // NOTE: Functionality is rather limited at the moment, only supports string values.
        IFResource* result = [self.core.resolver resolveURIFromString:uri];
        callback( [result asString] );
    }];
    
    // Handle a JS call to open a URL.
    [bridge registerHandler:@"epOpenURL" handler:^(id data, WVJBResponseCallback callback) {
        NSURL *url = [NSURL URLWithString:(NSString*)data];
        [[UIApplication sharedApplication] openURL:url];
        callback( [NSNumber numberWithBool:YES] );
    }];
    
    // Set the view controller's title.
    [bridge registerHandler:@"epSetTitle" handler:^(id data, WVJBResponseCallback callback) {
        self.title = [data description];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGSize size = self.view.frame.size;
    CGRect frame = CGRectMake(0, 0, size.width, size.height);
    webView.frame = frame;
    loadingImageView.frame = frame;
}

- (void)viewDidAppear:(BOOL)animated {
    if (firstAppearance) {
        [self loadContent];
    }
    [super viewDidAppear:animated];
    [[EPCore getCore] addDataObserver:self forConfiguration:configuration];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[EPCore getCore] removeDataObserver:self];
}

- (void)showSpinnerWithCompletion:(void(^)(void))block {
    if (spinner) {
        spinner.hidden = NO;
        // Execute the completion on the main ui thread, after the spinner has had a chance to display.
        dispatch_async(dispatch_get_main_queue(), block );
    }
    else block();
}

- (void)hideLoadingImage {
    if (loadingImageView && !loadingImageView.hidden) {
        [UIView animateWithDuration: 0.75
                              delay: 0.0
                            options: UIViewAnimationOptionCurveLinear
                         animations: ^{ loadingImageView.alpha = 0.0; }
                         completion: ^(BOOL finished) { loadingImageView.hidden = YES; }];
    }
}

- (void)loadContent {
    [self showSpinnerWithCompletion:^{
        IFResource *htmlRsc = [configuration getValueAsResource:@"html"];
        NSString *url = [configuration getValueAsString:@"url"];
        if (htmlRsc) {
            [self loadContentFromResource:htmlRsc];
        }
        else if (url) {
            // If the URL actually specifies an EP URI, then test whether the resource it resolves to can be referenced
            // by URL (currently, only IFFileResources can be referenced by URL).
            IFRegExp *re = [[IFRegExp alloc] initWithPattern:@"^(\\w+):"];
            NSArray *gs = [re match:url];
            if ([core isEPURIScheme:[gs objectAtIndex:1]]) {
                IFResource *r = [core resolveURIFromString:url];
                if ([r isKindOfClass:[IFFileResource class]]) {
                    url = [[(IFFileResource *)r externalURL] description];
                }
                else if (r) {
                    DDLogWarn(@"EPWebViewController: Unable to load content from non-file resource at %@", url);
                    return;
                }
                else {
                    DDLogWarn(@"EPWebViewController: Unable to load content, resource not found at %@", url);
                    return;
                }
            }
            self.contentResource = configuration.resource; // TODO: Is this needed?
            NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
            loadingExternalURL = YES;
            [webView loadRequest:req];
        }
        else {
            DDLogWarn(@"EPWevViewController: Unable to resolve content");
        }
    }];
}

- (void)loadContentFromResource:(id)resource {
    [super loadContentFromResource:resource];
    NSURL *baseURL;
    if ([resource isKindOfClass:[IFFileResource class]]) {
        baseURL = [(IFFileResource *)resource externalURL];
    }
    else {
        baseURL = [NSURL URLWithString:[configuration getValueAsString:@"baseURL" defaultValue:@"/"]];
    }
    // TODO: Check that the conversion to NSData will work as expected
    [webView loadData:[resource asData] MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:baseURL];

    // Load JSON, if configured.
    NSString *json = [configuration getValueAsString:@"json"];
    if (json) {
        [self loadContentFromJSON:json];
    }
}

- (void)loadContentFromJSON:(NSString *)json {
    if (injectJSONFn) {
        [self invokeJS:injectJSONFn withArgs:[NSArray arrayWithObject:json]];
    }
}

- (void)invokeJS:(NSString *)fnName withArgs:(NSArray *)args {
    EPWebViewJSFunctionCall *fnCall = [[EPWebViewJSFunctionCall alloc] initWithName:fnName args:args];
    dispatch_async(dispatch_get_main_queue(), ^{
        [jsCallQueue addObject:fnCall];
        [self processJSCallQueue];
    });
}

- (void)processJSCallQueue {
    if (webViewLoaded) {
        for (EPWebViewJSFunctionCall *fnCall in jsCallQueue) {
            [fnCall invokeOn:webView];
        }
        [jsCallQueue removeAllObjects];
    }
}

#pragma mark - data observer

- (void)notifyDataChangedAtPath:(NSString *)path inModel:(EPModel *)model {
    id value = [model getValueForPath:path];
    if (value && injectJSONFn) {
        NSString *json = nil;
        if ([value isKindOfClass:[NSString class]]) {
            json = [(NSString *)value JSONString];
        }
        else if ([value isKindOfClass:[NSArray class]]) {
            json = [(NSArray *)value JSONString];
        }
        else if ([value isKindOfClass:[NSDictionary class]]) {
            json = [(NSDictionary *)value JSONString];
        }
        if (json) {
            [self invokeJS:injectJSONFn withArgs:[NSArray arrayWithObject:json]];
        }
    }
}

- (void)destroyDataObserver {}

#pragma mark - web view delegate

- (void)webViewDidFinishLoad:(UIWebView *)view {
    [self hideLoadingImage];
    if (spinner) {
        spinner.hidden = YES;
    }
    if (useHTMLTitle) {
        NSString *title = [view stringByEvaluatingJavaScriptFromString:@"document.title"];
        if ([title length]) {
            self.title = title;
            if (self.parentViewController && shouldSetParentTitle) {
                self.parentViewController.title = title;
            }
        }
    }
    // Disable long touch events. See http://stackoverflow.com/questions/4314193/how-to-disable-long-touch-in-uiwebview
    [view stringByEvaluatingJavaScriptFromString:@"document.body.style.webkitTouchCallout='none'; document.body.style.KhtmlUserSelect='none'"];
    // Change console.log to use the epConsoleLog function.
    [view stringByEvaluatingJavaScriptFromString:@"console.log = epConsoleLog"];
    
    webViewLoaded = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self processJSCallQueue];
    });
    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = [request URL];
    if (allowExternalURLs) {
        NSString *surl = [url description];
        for (NSString *allowedURL in allowExternalURLs) {
            if ([surl hasPrefix:allowedURL]) {
                return YES;
            }
        }
    }
    if ([@"file" isEqualToString:url.scheme]) {
        loadingExternalURL = NO;
        return YES;
    }
    if ([core isEPURIScheme:url.scheme]) {
        [core dispatchURI:[url description] toHandler:self];
        return NO;
    }
    else if (loadingExternalURL) {
        loadingExternalURL = NO;
        return YES;
    }
    else if (loadExternalLinks) {
        return YES;
    }
    else if (webViewLoaded && (navigationType != UIWebViewNavigationTypeOther)) {
        [[UIApplication sharedApplication] openURL:url];
        return NO;
    }
    return YES;
    //return navigationType == UIWebViewNavigationTypeOther;
}

@end

@implementation EPWebViewJSFunctionCall

- (id)initWithName:(NSString *)_name args:(NSArray *)_args {
    self = [super init];
    if (self) {
        name = _name;
        args = _args;
    }
    return self;
}

- (void)invokeOn:(UIWebView *)webView {
    NSMutableString *js = [[NSMutableString alloc] init];
    [js appendString:name];
    [js appendString:@"("];
    BOOL delimit = NO;
    for (NSString *arg in args) {
        if (delimit) {
            [js appendString:@","];
        }
        else delimit = YES;
        //[js appendString:@"'"];
        [js appendString:[[arg description] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]];
        //[js appendString:@"'"];
    }
    [js appendString:@")"];
    NSString *result = [webView stringByEvaluatingJavaScriptFromString:js];
    NSLog(@"[WebView] JS result: %@", result);
}

@end
