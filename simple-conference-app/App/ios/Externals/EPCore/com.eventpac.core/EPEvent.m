//
//  EPEvent.m
//  EPCore
//
//  Created by Julian Goacher on 23/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPEvent.h"
#import "EPViewResource.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

@implementation EPEvent

- (id)initWithData:(id)data uri:(IFCompoundURI *)uri parent:(IFResource *)parent {
    self = [super initWithData:data uri:uri parent:parent];
    if (self) {
        self.name = uri.name;
        self.action = uri.fragment;
    }
    return self;
}

- (UIViewController *)resolveViewArgument {
    UIViewController *result = nil;
    IFResource *viewRsc = [self.arguments objectForKey:@"view"];
    if (![viewRsc isKindOfClass:[EPViewResource class]]) {
        // The 'view' argument has been specified as a view name, so needs to be promoted to
        // a full view: URI which can then be used to resolve the actual view. In this mode,
        // any other event arguments are copied to the view URI as additional arguments.
        
        // Create a map of all event arguments, excluding the 'view' argument.
        NSMutableDictionary *viewArgs = [[NSMutableDictionary alloc] init];
        for (NSString *name in [self.arguments allKeys]) {
            if (![@"view" isEqualToString:name]) {
                IFResource *r = [self.arguments objectForKey:name];
                [viewArgs setObject:r.uri forKey:name];
            }
        }
        // Copy the s: (string) URI into the view: scheme space - this will preserve any parameters on the s: URI -
        // and add the event arguments to the new URI.
        IFCompoundURI *uri = [[IFCompoundURI alloc] initWithScheme:@"view" uri:viewRsc.uri];
        [uri addURIParameters:viewArgs];
        viewRsc = [viewRsc resolveURI:uri];
    }
    if ([viewRsc isKindOfClass:[EPViewResource class]]) {
        result = [(EPViewResource *)viewRsc asView];
    }
    if (!result) {
        DDLogCWarn(@"EPViewController: Can't resolve view for event %@", self.uri);
    }
    return result;
}

- (EPEvent *)copyWithName:(NSString *)name {
    EPEvent *result = [self copy];
    result.name = name;
    return result;
}

static id NotHandledResult;

+ (void)initialize {
    if (!NotHandledResult) {
        NotHandledResult = [[NSObject alloc] init];
    }
}

+ (id)notHandledResult {
    return NotHandledResult;
}

+ (BOOL)isNotHandled:(id)result {
    return result == NotHandledResult;
}

@end
