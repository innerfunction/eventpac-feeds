//
//  EPWebViewController.h
//  EPCore
//
//  Created by Julian Goacher on 04/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPViewController.h"
#import "EPDataObserver.h"
#import "WebViewJavascriptBridge.h"

#define WEBVIEW_JAVASCRIPT_BRIDGE_LOGGING_ENABLED 1

@interface EPWebViewController : EPViewController <UIWebViewDelegate, EPDataObserver> {
    UIWebView* webView;
    UIImageView* loadingImageView;
    BOOL loadingExternalURL;
    BOOL webViewLoaded;
    BOOL loadExternalLinks;
    UIActivityIndicatorView* spinner;
    WebViewJavascriptBridge* bridge;
    BOOL useHTMLTitle;
    BOOL shouldSetParentTitle;
    NSMutableArray *jsCallQueue;
    NSString *injectJSONFn;
    NSArray *allowExternalURLs;
}

- (void)invokeJS:(NSString *)fnName withArgs:(NSArray *)args;
- (void)loadContent;

@end

@interface EPWebViewJSFunctionCall : NSObject {
    NSString *name;
    NSArray *args;
}

- (id)initWithName:(NSString *)_name args:(NSArray *)_args;
- (void)invokeOn:(UIWebView *)webView;

@end