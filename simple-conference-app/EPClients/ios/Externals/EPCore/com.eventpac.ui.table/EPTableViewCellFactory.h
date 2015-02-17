//
//  EPTableViewCell.h
//  EventPacComponents
//
//  Created by Julian Goacher on 29/10/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "EPConfiguration.h"
#import "EPCore.h"
#import "EPTableData.h"
#import "IFResource.h"

@class EPTableViewController;
@class EPTableViewCellFactory;

@protocol EPTableViewCellDecorator <NSObject>

- (UITableViewCell *)decorateCell:(UITableViewCell *)cell data:(NSDictionary *)data factory:(EPTableViewCellFactory *)factory;

@end

@interface EPTableViewCellFactory : NSObject {
    EPConfiguration *configuration;
    EPCore *core;
    NSCache *imageCache;
    id<EPTableViewCellDecorator> decorator;
}

//@property (nonatomic, strong) EPTableViewController *parent;
@property (nonatomic, strong) EPTableData *tableData;
@property (nonatomic, strong) IFResource *baseResource;
@property (nonatomic, strong) EPConfiguration *rowConfiguration;

- (id)initWithConfiguration:(EPConfiguration *)config;
- (UITableViewCell *)resolveCellForTable:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;
- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
