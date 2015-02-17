//
//  EPJSONData.h
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EPJSONDataValueContext : NSObject

@property (nonatomic, strong) EPJSONDataValueContext *parent;
@property (nonatomic, strong) id object;
@property (nonatomic, strong) NSString *name;

- (id)getValue;
- (id)createValue;
- (id)setValue:(id)value;
- (void)removeValue;

+ (EPJSONDataValueContext *)valueContextWithParent:(EPJSONDataValueContext *)parent name:(NSString *)name object:(id)object;

@end

@interface EPJSONData : NSObject {
    EPJSONDataValueContext *root;
}

- (id)initWithData:(id)data;
- (EPJSONDataValueContext *)getValueContextForPath:(NSString *)path insertMissing:(BOOL)insertMissing;
- (id)getValueAtPath:(NSString *)path;
- (void)setValue:(id)value atPath:(NSString *)path;
- (void)removeValueAtPath:(NSString *)path;

@end
