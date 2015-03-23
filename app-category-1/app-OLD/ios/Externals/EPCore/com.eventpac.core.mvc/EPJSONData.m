//
//  EPJSONData.m
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPJSONData.h"
#import "NSDictionary+IF.h"
#import "JSONKit.h"

/**
 * A class for addressing and modifying data using JS/JSON style dotted path notation.
 * The key mechanism of this class is the EPJSONDataValueContext class, which is used to represent a data node
 * as follows:
 *              object
 *     parent  +------+
 *   <---------+      |  value   +------+
 *             |[name]---------->|      |
 *             |      |<---------+      |
 *             +------+          |      |
 *                               +------+
 * That is:
 * - an EPJSONDataValueContext (value context) represents a named property on an object.
 * - the value context's 'value' is the object referenced by 'name' on 'object' (e.g. object = { name: value })
 * - the value context's 'parent' is the inverse of the 'value' relationship.
 * The value context uses the NSDictionary(IF) category to add new properties to objects. This category will
 * modify a dictionary in-place if it is mutable, but otherwise will return a new mutable dictionary extension of
 * the original dictionary. When this happens, the 'object' of the current value context, and the 'value' of the
 * parent value context, must be updated.
 * Because of this last requirement, the root of this class' object graph is represented using a value context
 * with a default root object of { root: <data> }.
 */
@implementation EPJSONData

- (id)init {
    return [self initWithData:[NSMutableDictionary dictionary]];
}

- (id)initWithData:(id)data {
    self = [super init];
    if (self) {
        if (data) {
            id object = [NSMutableDictionary dictionaryWithObject:data forKey:@"root"];
            root = [EPJSONDataValueContext valueContextWithParent:nil name:@"root" object:object];
        }
    }
    return self;
}

- (EPJSONDataValueContext *)getValueContextForPath:(NSString *)path insertMissing:(BOOL)insertMissing {
    EPJSONDataValueContext *vctx = root;
    id object = [vctx getValue];
    NSArray *names = [path componentsSeparatedByString:@"."];
    NSInteger len = [names count];// - 1;
    for (NSInteger i = 0; i < len && object != nil; i++) {
        NSString *name = [names objectAtIndex:i];
        vctx = [EPJSONDataValueContext valueContextWithParent:vctx name:name object:object];
        // Resolve the next object along the path.
        object = [vctx getValue];
        // If no next object found and insertMissing is true then create a new property.
        if (object == nil && insertMissing) {
            object = [vctx createValue];
        }
    }
    return vctx;
}

- (id)getValueAtPath:(NSString *)path {
    if (!(path || [path length])) {
        return root;
    }
    EPJSONDataValueContext *vctx = [self getValueContextForPath:path insertMissing:NO];
    // NOTE: vctx.object can be null if this.root is null - can happen for row models.
    return vctx ? [vctx getValue] : nil;
}

- (void)setValue:(id)value atPath:(NSString *)path {
    EPJSONDataValueContext *vctx = [self getValueContextForPath:path insertMissing:YES];
    if (vctx) {
        [vctx setValue:value];
    }
}

- (void)removeValueAtPath:(NSString *)path {
    EPJSONDataValueContext *vctx = [self getValueContextForPath:path insertMissing:NO];
    if (vctx) {
        [vctx removeValue];
    }
}

- (NSString *)description {
    return [[root getValue] JSONString];
}

@end

@implementation EPJSONDataValueContext

- (id)getValue {
    id value = nil;
    if ([_object isKindOfClass:[NSDictionary class]]) {
        value = [(NSDictionary *)_object objectForKey:_name];
    }
    else if ([_object isKindOfClass:[NSArray class]]) {
        // NOTE that [NSString integerValue] returns 0 for non-integer string values, so there is no
        // attempt here to detect when 'name' isn't an array index; this may produce divergent behaviour
        // from the Android framework.
        NSInteger idx = [_name integerValue];
        NSArray *array = (NSArray *)_object;
        if (idx < [array count]) {
            value = [array objectAtIndex:idx];
        }
    }
    return value;
}

- (id)createValue {
    return [self setValue:[[NSMutableDictionary alloc] init]];
}

- (id)setValue:(id)value {
    if (value == nil) {
        value = [NSNull null];
    }
    id property = nil;
    if ([_object isKindOfClass:[NSDictionary class]]) {
        property = value;
        _object = [(NSDictionary *)_object dictionaryWithAddedObject:property forKey:_name];
        if (_parent) {
            [_parent setValue:_object];
        }
    }
    return property;
}

- (void)removeValue {
    if ([_object respondsToSelector:@selector(removeObjectForKey:)]) {
        [(NSMutableDictionary *)_object removeObjectForKey:_name];
    }
}

+ (EPJSONDataValueContext *)valueContextWithParent:(EPJSONDataValueContext *)parent name:(NSString *)name object:(id)object {
    EPJSONDataValueContext *vctx = [[EPJSONDataValueContext alloc] init];
    vctx.parent = parent;
    vctx.name = name;
    vctx.object = object;
    return vctx;
}

@end
