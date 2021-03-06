//
//  IFDBHelper.h
//  EPCore
//
//  Created by Julian Goacher on 25/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlausibleDatabase.h"

@protocol IFDBHelperDelegate <NSObject>

- (void)onCreate:(id<PLDatabase>)database;

- (void)onUpgrade:(id<PLDatabase>)database from:(int)oldVersion to:(int)newVersion;

@optional

- (void)onOpen:(id<PLDatabase>)database;

@end

@interface IFDBHelper : NSObject <PLDatabaseMigrationDelegate> {
    NSString *databaseName;
    int databaseVersion;
    id<PLDatabaseConnectionProvider> connectionProvider;
    id<PLDatabase> database;
}

@property (nonatomic, strong) id<IFDBHelperDelegate> delegate;

- (id)initWithName:(NSString *)name version:(int)version;

- (BOOL)deleteDatabase;

- (id<PLDatabase>)getDatabase;

- (void)close;

@end
