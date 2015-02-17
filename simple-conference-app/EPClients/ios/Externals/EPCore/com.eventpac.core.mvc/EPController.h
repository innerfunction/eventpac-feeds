//
//  EPController.h
//  EPCore
//
//  Created by Julian Goacher on 22/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPService.h"
#import "EPJSONModel.h"
#import "IFURIResolver.h"
#import "IFResourceObserver.h"

@class EPDBController;

@interface EPController : NSObject <EPService> {
    EPConfiguration *configuration;
    NSDictionary *resourceModelsByScheme;
}

@property (nonatomic, strong) EPJSONModel *globalModel;
@property (nonatomic, strong) IFStandardURIResolver *resolver;
@property (nonatomic, strong) EPDBController *dbController;

- (void)setGlobalValue:(id)value forName:(NSString *)name;
- (void)notifyResourceObserversOfScheme:(NSString *)scheme path:(NSString *)path;
- (void)notifyResourceObserversOfURI:(IFCompoundURI *)uri;
- (BOOL)addResourceObserver:(id<IFResourceObserver>)observer forResource:(IFResource *)resource;
- (BOOL)addResourceObserver:(id<IFResourceObserver>)observer forURI:(IFCompoundURI *)uri;
- (void)removeResourceObserver:(id<IFResourceObserver>)observer forResource:(IFResource *)resource;
- (void)removeResourceObserver:(id<IFResourceObserver>)observer forURI:(IFCompoundURI *)uri;

@end

@interface EPControllerGlobalValueResourceObserver : NSObject <IFResourceObserver>

@property (nonatomic, strong) EPController *controller;
@property (nonatomic, strong) IFResource *resource;
@property (nonatomic, strong) NSString *dataName;

- (id)initWithController:(EPController *)controller resource:(IFResource *)resource dataName:(NSString *)dataName;

@end