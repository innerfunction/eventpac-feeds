//
//  EPConfiguration.m
//  EventPacComponents
//
//  Created by Julian Goacher on 07/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "EPConfiguration.h"
#import "IFRegExp.h"
#import "IFStringTemplate.h"
#import "IFTypeConversions.h"
#import "EPCore.h"
#import "NSDictionary+IF.h"
#import "UIColor+IF.h"
#import "IFCore.h"

static const int ddLogLevel = IFCoreLogLevel;

@interface EPConfiguration()

- (id)initWithData:(id)data parent:(EPConfiguration *)parent;
- (id)initWithConfiguration:(EPConfiguration *)config parent:(EPConfiguration *)parent;
- (void)initializeContext;

@end

@implementation EPConfigurationPropertyHandler

- (id)initWithConfiguration:(EPConfiguration *)_parent {
    self = [super init];
    if (self) {
        parent = _parent;
    }
    return self;
}

- (id)resolveName:(NSString *)name on:(id)value representation:(NSString *)representation {
    if ([value isKindOfClass:[IFResource class]]) {
        value = [(IFResource *)value asJSONData];
    }
    return [super resolveName:name on:value representation:representation];
}

- (id)modifyValue:(id)value forName:(id)name representation:(NSString *)representation {
    if ([value isKindOfClass:[NSString class]]) {
        // Interpret the string value.
        NSString* stringValue = (NSString *)value;

        // First, attempt resolving any context references. If these in turn resolve to a
        // $ or # prefixed value, then they will be resolved in the following code.
        if ([stringValue hasPrefix:@"$"]) {
            value = [parent.context objectForKey:stringValue];
            if ([value isKindOfClass:[NSString class]]) {
                stringValue = (NSString *)value;
            }
            else {
                return value;
            }
        }
        
        // Evaluate all string values as templates, unless prefixed with `
        if (![stringValue hasPrefix:@"`"]) {
            stringValue = [IFStringTemplate render:(NSString*)stringValue context:parent.context];
        }
        
        // Any string values starting with a '@' are potentially internal URI references.
        // Normalize to URI references with a default representation qualifier.
        // If a dispatcher is also set on this configuration object then attempt to resolve
        // the URI and return its value instead.
        if ([stringValue hasPrefix:@"@"]) {
            NSString* uri = [stringValue substringFromIndex:1];
            value = [parent.resource resolveURIFromString:uri];
        }
        // Any string values starting with a '#' are potential path references to other
        // properties in the same configuration. Attempt to resolve them against the configuration
        // root; if they don't resolve then return the original value.
        else if ([stringValue hasPrefix:@"#"]) {
            value = [parent.root getValue:[stringValue substringFromIndex:1] asRepresentation:representation];
            if (value == nil) {
                value = stringValue;
            }
        }
        else if ([stringValue hasPrefix:@"`"]) {
            value = [stringValue substringFromIndex:1];
        }
        else if (stringValue) {
            value = stringValue;
        }
    }
    return value;
}

@end

@implementation EPConfiguration

@synthesize data, root, resource, context;

- (id)init {
    // Initialize with an empty dictionary.
    return [self initWithData:[NSDictionary dictionary]];
}

- (id)initWithData:(id)_data {
    return [self initWithData:_data resource:[EPCore getCore]];
}

- (id)initWithData:(id)_data parent:(EPConfiguration *)parent {
    self = [super init];
    if (self) {
        self.data = _data;
        self.resource = parent.resource;
        self.root = parent.root;
        self.context = parent.context;
        [self initializeContext];
        propertyHandler = [[EPConfigurationPropertyHandler alloc] initWithConfiguration:self];
    }
    return self;
}

- (id)initWithConfiguration:(EPConfiguration *)config parent:(EPConfiguration *)parent {
    self = [super init];
    if (self) {
        NSDictionary *_data = [[NSMutableDictionary alloc] init];
        if ([config.data isKindOfClass:[NSDictionary class]]) {
            _data = [_data extendWith:(NSDictionary *)config.data];
        }
        if ([parent.data isKindOfClass:[NSDictionary class]]) {
            _data = [_data extendWith:(NSDictionary *)parent.data];
        }
        self.data = _data;
        self.resource = parent.resource;
        self.root = parent.root;
        self.context = [config.context extendWith:parent.context];
        [self initializeContext];
        propertyHandler = [[EPConfigurationPropertyHandler alloc] initWithConfiguration:self];
    }
    return self;
}

- (id)initWithResource:(IFResource *)_resource {
    return [self initWithData:[_resource asJSONData] resource:_resource];
}

- (id)initWithData:(id)_data resource:(IFResource *)_resource {
    if (self = [super init]) {
        self.data = _data;
        self.resource = _resource;
        self.root = self;
        [self initializeContext];
        propertyHandler = [[EPConfigurationPropertyHandler alloc] initWithConfiguration:self];
    }
    return self;
}

- (id)initWithResource:(IFResource *)_resource parent:(EPConfiguration *)parent {
    self = [super init];
    if (self) {
        self.data = [_resource asJSONData];
        self.resource = _resource;
        // If the current resource and the parent's resource share the same scheme and name then they
        // refer to the same container, and this configuration shares the parent's root; otherwise, the
        // root is this resource.
        IFCompoundURI *thisURI = _resource.uri;
        IFCompoundURI *parentURI = parent.resource.uri;
        if ([thisURI.scheme isEqualToString:parentURI.scheme] && [thisURI.name isEqualToString:parentURI.name]) {
            self.root = parent.root;
        }
        else {
            self.root = self;
        }
        self.context = parent.context;
        [self initializeContext];
        propertyHandler = [[EPConfigurationPropertyHandler alloc] initWithConfiguration:self];
    }
    return self;
}

- (void)initializeContext {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    // Search the configuration data for any parameter values, filter parameter values out of main data values.
    for (NSString *name in [data allKeys]) {
        if ([name hasPrefix:@"$"]) {
            [params setObject:[data objectForKey:name] forKey:name];
        }
        else {
            [values setObject:[data objectForKey:name] forKey:name];
        }
    }
    // Initialize/modify the context with parameter values, if any.
    if ([params count]) {
        if (self.context) {
            self.context = [self.context extendWith:params];
        }
        else {
            self.context = params;
        }
        self.data = values;
    }
    else if (!self.context) {
        self.context = [NSDictionary dictionary];
    }
}

- (id)getValue:(NSString*)name asRepresentation:(NSString *)representation {
    
    id value = [IFJSONData resolvePath:name onData:data handler:propertyHandler representation:representation];
    
    // Perform type conversions according to the requested representation.
    // These are pretty basic:
    // * If the requested representation is 'resource', and the value isn't already a result, then
    //   construct a new resource with the current value. Note that the new resource URI is the same
    //   as this configuration's base resource.
    // Otherwise:
    // * A Resource can be converted to anything its getRepresentation method supports;
    // * A String can be converted to a URL and is valid JSON data;
    // * A Number can be converted to a String and is valid JSON data;
    // * Anything else is only valid JSON data.
    if ([@"resource" isEqualToString:representation]) {
        if ( value && ![value isKindOfClass:[IFResource class]]) {
            IFCompoundURI *uri = [resource.uri copyOfWithFragment:name];
            value = [[IFResource alloc] initWithData:value uri:uri parent:resource];
        }
    }
    else if ([@"configuration" isEqualToString:representation]) {
        if (![value isKindOfClass:[EPConfiguration class]]) {
            // If value isn't already a configuration, but is a dictionary then construct a new config using the values in that dictionary...
            if ([value isKindOfClass:[NSDictionary class]]) {
                IFCompoundURI *uri = [resource.uri copyOfWithFragment:name];
                IFResource *r = [[IFResource alloc] initWithData:value uri:uri parent:resource];
                value = [[EPConfiguration alloc] initWithResource:r parent:self];
            }
            // Else if value is a resource, then construct a new config using the resource...
            else if ([value isKindOfClass:[IFResource class]]) {
                value = [[EPConfiguration alloc] initWithResource:(IFResource *)value parent:self];
            }
            // Else the value can't be resolved to a resource, so return nil.
            else {
                value = nil;
            }
        }
    }
    else if ([value isKindOfClass:[IFResource class]]) {
        value = [(IFResource*)value asRepresentation:representation];
    }
    else if (![@"json" isEqualToString:representation]) {
        value = [IFTypeConversions value:value asRepresentation:representation];
    }
    return value;
}

- (BOOL)hasValue:(NSString *)name {
    return [self getValue:name asRepresentation:@"default"] != nil;
}

- (NSString *)getValueAsString:(NSString *)name {
    return [self getValueAsString:name defaultValue:nil];
}

- (NSString *)getValueAsString:(NSString*)name defaultValue:(NSString*)defaultValue {
    NSString* value = [self getValue:name asRepresentation:@"string"];
    return value == nil || ![value isKindOfClass:[NSString class]] ? defaultValue : value;
}

- (NSString *)getValueAsLocalizedString:(NSString *)name {
    NSString *value = [self getValueAsString:name];
    return value == nil ? nil : NSLocalizedString(value, @"");
}

- (NSNumber *)getValueAsNumber:(NSString *)name {
    return [self getValueAsNumber:name defaultValue:nil];
}

- (NSNumber *)getValueAsNumber:(NSString*)name defaultValue:(NSNumber*)defaultValue {
    NSNumber* value = [self getValue:name asRepresentation:@"number"];
    return value == nil || ![value isKindOfClass:[NSNumber class]] ? defaultValue : value;
}

- (BOOL)getValueAsBoolean:(NSString *)name {
    return [self getValueAsBoolean:name defaultValue:NO];
}

- (BOOL)getValueAsBoolean:(NSString*)name defaultValue:(BOOL)defaultValue {
    NSNumber* value = [self getValue:name asRepresentation:@"number"];
    return value == nil ? defaultValue : [value boolValue];
}

// Resolve a date value on the cell data at the specified path.
- (NSDate *)getValueAsDate:(NSString *)name {
    return [self getValueAsDate:name defaultValue:nil];
}

// Resolve a date value on the cell data at the specified path, return the default value if not set.
- (NSDate *)getValueAsDate:(NSString *)name defaultValue:(NSDate *)defaultValue {
    NSDate *value = [self getValue:name asRepresentation:@"date"];
    return value == nil || ![value isKindOfClass:[NSDate class]] ? defaultValue : value;
}

- (UIColor *)getValueAsColor:(NSString *)name {
    NSString *hexValue = [self getValueAsString:name];
    return hexValue ? [UIColor colorForHex:hexValue] : nil;
}

- (UIColor *)getValueAsColor:(NSString *)name defaultValue:(UIColor *)defaultValue {
    UIColor *color = [self getValueAsColor:name];
    return color ? color : defaultValue;
}

- (NSURL *)getValueAsURL:(NSString *)name {
    NSURL *value = [self getValue:name asRepresentation:@"url"];
    return [value isKindOfClass:[NSURL class]] ? value : nil;
}

- (NSData *)getValueAsData:(NSString *)name {
    NSData *value = [self getValue:name asRepresentation:@"data"];
    return [value isKindOfClass:[NSData class]] ? value : nil;
}

- (UIImage *)getValueAsImage:(NSString *)name {
    UIImage *value = [self getValue:name asRepresentation:@"image"];
    return [value isKindOfClass:[UIImage class]] ? value : nil;
}

- (IFResource *)getValueAsResource:(NSString *)name {
    IFResource *value = [self getValue:name asRepresentation:@"resource"];
    return [value isKindOfClass:[IFResource class]] ? value : nil;
}

- (id)getValue:(NSString *)name {
    return [self getValue:name asRepresentation:@"default"];
}

- (NSArray *)getValueNames {
    if ([data respondsToSelector:@selector(allKeys)]) {
        return [data allKeys];
    }
    return [NSArray array];
}

- (EPValueType)getValueType:(NSString *)name {
    id value = [self getValue:name asRepresentation:@"json"];
    if (value == nil)                           return EPValueTypeUndefined;
    // NOTE: Can't reliably detect boolean here, as boolean values are represented using NSNumber.
    if ([value isKindOfClass:[NSNumber class]]) return EPValueTypeNumber;
    if ([value isKindOfClass:[NSString class]]) return EPValueTypeString;
    if ([value isKindOfClass:[NSArray class]])  return EPValueTypeList;
    return EPValueTypeObject;
}

- (EPConfiguration *)getValueAsConfiguration:(NSString *)name {
    return [self getValue:name asRepresentation:@"configuration"];
}

- (EPConfiguration *)getValueAsConfiguration:(NSString *)name defaultValue:(EPConfiguration *)defaultValue {
    EPConfiguration *result = [self getValueAsConfiguration:name];
    return result ? result : defaultValue;
}

- (NSArray *)getValueAsConfigurationList:(NSString *)name {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if ([self getValueType:name] == EPValueTypeList) {
        NSArray *valuesArray = (NSArray *)[self getValue:name];
        if (![valuesArray isKindOfClass:[NSArray class]]) {
            valuesArray = [self getValue:name asRepresentation:@"json"];
        }
        if ([valuesArray isKindOfClass:[NSArray class]]) {
            for (NSInteger i = 0; i < [valuesArray count]; i++) {
                NSString *itemName = [NSString stringWithFormat:@"%@.%ld", name, (long)i];
                EPConfiguration *item = [self getValueAsConfiguration:itemName];
                [result addObject:item];
            }
        }
    }
    return result;
}

- (NSDictionary *)getValueAsConfigurationMap:(NSString *)name {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    id values = [self getValue:name];
    if ([values isKindOfClass:[NSDictionary class]]) {
        NSDictionary *valuesDictionary = (NSDictionary *)values;
        for (id key in [valuesDictionary allKeys]) {
            NSString *itemName = [NSString stringWithFormat:@"%@.%@", name, key];
            EPConfiguration *item = [self getValueAsConfiguration:itemName];
            [result setObject:item forKey:key];
        }
    }
    return result;
}

- (EPConfiguration *)mergeConfiguration:(EPConfiguration *)otherConfig {
    // See note in Configuration.java about the parent argument below.
    return [[EPConfiguration alloc] initWithConfiguration:self parent:otherConfig];
}

- (EPConfiguration *)extendWithParameters:(NSDictionary *)params {
    EPConfiguration *result = self;
    if ([params count] > 0) {
        result = [[EPConfiguration alloc] initWithData:self.data parent:self];
        NSMutableDictionary *$params = [[NSMutableDictionary alloc] initWithCapacity:[params count]];
        for (NSString *name in [params allKeys]) {
            [$params setObject:[params objectForKey:name] forKey:[NSString stringWithFormat:@"$%@", name]];
        }
        result.context = [result.context extendWith:$params];
    }
    return result;
}

- (EPConfiguration *)normalize {
    // Start by flattening this configuration (i.e. merging its "config" property into the top level).
    EPConfiguration *result = [self flatten];
    // Next, start processing the "extends" chain...
    EPConfiguration *current = result;
    // A set of previously visited parent configurations, to detect dependency loops.
    NSMutableSet *visited = [[NSMutableSet alloc] init];
    while ([current getValueType:@"extends"] == EPValueTypeObject) {
        current = [current getValueAsConfiguration:@"extends"];
        if ([visited containsObject:current]) {
            // Dependency loop detected, stop extending the config.
            break;
        }
        [visited addObject:current];
        result = [[current flatten] mergeConfiguration:result];
    }
    return result;
}

- (EPConfiguration *)flatten {
    EPConfiguration *result = self;
    if ([self getValueType:@"config"] == EPValueTypeObject) {
        result = [self mergeConfiguration:[self getValueAsConfiguration:@"config"]];
    }
    return result;
}

- (NSUInteger)hash {
    return self.resource ? [self.resource hash] : [super hash];
}

- (BOOL)isEqual:(id)object {
    // Two configurations are equal if the have the same source resource.
    return [object isKindOfClass:[EPConfiguration class]] && [self.resource isEqual:((EPConfiguration *)object).resource];
}

static EPConfiguration *emptyConfiguaration;

+ (void)initialize {
    emptyConfiguaration = [[EPConfiguration alloc] init];
}

+ (EPConfiguration *)emptyConfiguration {
    return emptyConfiguaration;
}

@end
