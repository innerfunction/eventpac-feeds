//
//  EPAliasResourceModel.h
//  EPCore
//
//  Created by Julian Goacher on 27/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "EPResourceModel.h"
#import "EPController.h"
#import "IFResourceObserver.h"

@class EPAliasSchemeHandler;

@interface EPAliasResourceModel : EPResourceModel

@property (nonatomic, strong) EPController *controller;
@property (nonatomic, strong) EPAliasSchemeHandler *aliasSchemeHandler;

- (id)initWithController:(EPController *)controller handler:(EPAliasSchemeHandler *)handler;

@end

@interface EPAliasedResourceObserver : NSObject <IFResourceObserver> {
    NSString *alias;
    IFCompoundURI *uri;
    id<IFResourceObserver> observer;
    EPAliasResourceModel *model;
}

- (id)initWithAlias:(NSString *)_alias observer:(id<IFResourceObserver>)_observer model:(EPAliasResourceModel *)_model;
- (void)updateURI;
- (void)remove;

@end

@interface EPAliasedDataObserver : NSObject <EPDataObserver> {
    EPAliasedResourceObserver *aliasedResourceObserver;
}

- (id)initWithResourceObserver:(EPAliasedResourceObserver *)observer;

@end