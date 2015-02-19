//
//  EPResourceModel.h
//  EPCore
//
//  Created by Julian Goacher on 26/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPModel.h"
#import "IFURIResolver.h"
#import "IFResourceObserver.h"

@interface EPResourceModel : EPModel {
    id<IFURIResolver> resolver;
    NSMutableDictionary *dataObserverLookup;
}

- (id)getValueForURI:(IFCompoundURI *)uri;
- (void)addDataObserver:(id<EPDataObserver>)observer forURI:(IFCompoundURI *)uri;
- (void)notifyDataObserversForURI:(IFCompoundURI *)uri;
- (void)addResourceObserver:(id<IFResourceObserver>)observer forURI:(IFCompoundURI *)uri;
- (void)removeResourceObserver:(id<IFResourceObserver>)observer;
- (id<EPDataObserver>)createDataObserverForResourceObserver:(id<IFResourceObserver>)observer uri:(IFCompoundURI *)uri;

@end

@interface EPResourceModelDataObserver : NSObject <EPDataObserver> {
    id<IFResourceObserver> resourceObserver;
}

- (id)initWithResourceObserver:(id<IFResourceObserver>)observer;

@end