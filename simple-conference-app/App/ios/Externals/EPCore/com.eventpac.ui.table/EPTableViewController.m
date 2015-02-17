//
//  EPTableViewController.m
//  EventPacComponents
//
//  Created by Julian Goacher on 07/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//
// 20140202 - Changes to operation and configuration property names:
// 1. Data lookup in cellForRowAtIndexPath: has been modified so that cell data is resolved once at
//    the start of the method, and row data is then resolved against the result. (Previously, the
//    cell data was resolved each time a row property was needed).
// 2. The default row configuration properties have been moved under a "row" property on the table's
//    configuration. This is so that these properties can share the same property names as those in
//    the cell data. So e.g. rowTextColor -> textColor.

#import <QuartzCore/QuartzCore.h>
#import <Availability.h>
#import "EPCore.h"
#import "EPTableViewController.h"
#import "EPViewFactoryService.h"
#import "UIColor+IF.h"
#import "UIImage+CropScale.h"
#import "UIViewController+EP.h"

#define EPEventPrefix   @"table/"

@interface EPTableViewController ()

- (void)hideSearchBar;

@end

@implementation EPTableViewController

@synthesize core;

- (id)initWithConfiguration:(EPConfiguration *)config {
    configuration = config;
    UITableViewStyle style;
    NSString *value = [configuration getValueAsString:@"tableStyle" defaultValue:@"Plain"];
    if ([value isEqualToString:@"Grouped"]) {
        style = UITableViewStyleGrouped;
    }
    else {
        style = UITableViewStylePlain;
    }
    self = [super initWithStyle:style];
    if (self) {

        tableData = [[EPTableData alloc] init];
        [self applyStandardConfiguration:configuration];

        NSMutableDictionary *factories = [[NSMutableDictionary alloc] init];
        // A "displayModes" property allows a set of different table cell configurations to be specified for different
        // table data display modes. Its format is:
        //      "displayModes": {
        //          "modeName1": { ... config ... }
        //          "modeName2": { ... config ... }
        // etc. See the [displayModeForIndexPath:] and [cellFactoryForIndexPath:] methods.
        EPConfiguration *displayModes = [configuration getValueAsConfiguration:@"displayModes"];
        if (displayModes) {
            for (NSString *modeName in [displayModes getValueNames]) {
                EPConfiguration *displayMode = [displayModes getValueAsConfiguration:modeName];
                // Merge the display mode over the table's config, so that default mode values can be defined
                // on the table's config.
                displayMode = [config mergeConfiguration:displayMode];
                EPTableViewCellFactory *factory = [[EPTableViewCellFactory alloc] initWithConfiguration:displayMode];
                factory.tableData = tableData;
                [factories setObject:factory forKey:modeName];
                if (!defaultFactory) {
                    defaultFactory = factory;
                }
            }
        }
        if (!defaultFactory) {
            defaultFactory = [[EPTableViewCellFactory alloc] initWithConfiguration:configuration];
            defaultFactory.tableData = tableData;
        }
        cellFactoriesByDisplayMode = factories;
        
        NSString *_sectionTitleColor = [config getValueAsString:@"sectionTitleColor"];
        if (_sectionTitleColor) {
            sectionTitleColor = [UIColor colorForHex:_sectionTitleColor];
        }
        NSString *_sectionTitleBackgroundColor = [config getValueAsString:@"sectionTitleBackgroundColor"];
        if (_sectionTitleBackgroundColor) {
            sectionTitleBackgroundColor = [UIColor colorForHex:_sectionTitleBackgroundColor];
        }
        
        scrollToSelected = NO;
        self.selectedID = [configuration getValueAsString:@"selectedID"];
        
        filterByFavouritesMessage = [configuration getValueAsLocalizedString:@"filterByFavouritesMessage"];
        clearFilterMessage = [configuration getValueAsLocalizedString:@"clearFilterMessage"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self applyStandardOnLoadConfiguration:configuration];

    self.clearsSelectionOnViewWillAppear = [configuration getValueAsBoolean:@"ios:clearsSelectionOnViewWillAppear" defaultValue:NO];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    if ([configuration getValueAsBoolean:@"hasSearchBar" defaultValue:NO]) {
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        searchBar.delegate = self;
        searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
        searchDisplayController.delegate = self;
        searchDisplayController.searchResultsDataSource = self;
        self.tableView.tableHeaderView = searchBar;
    }
    [self loadContent];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.selectedID) {
        NSIndexPath *selectedPath = [tableData pathForRowWithValue:self.selectedID forField:@"id"];
        if (selectedPath) {
            [self.tableView selectRowAtIndexPath:selectedPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            scrollToSelected = YES;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self applyStandardOnAppearConfiguration:configuration];    
    [self hideSearchBar];
    if (scrollToSelected) {
        [self.tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [tableData sectionCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tableData sectionSize:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [tableData sectionTitle:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EPTableViewCellFactory *cellFactory = [self cellFactoryForIndexPath:indexPath];
    return [cellFactory resolveCellForTable:tableView indexPath:indexPath];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *action = [[tableData dataForPath:indexPath] getValueAsString:@"action"];
    if (action) {
        // Resolve the event handler. Note: We don't assign self.eventHandler = self by default to
        // avoid creating an arc memory leak.
        id<EPEventHandler> eventHandler = self.eventHandler;
        if (!eventHandler) {
            eventHandler = self;
        }
        [self.core dispatchAction:action toHandler:eventHandler];
    }
    [tableData clearFilter];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    EPTableViewCellFactory *cellFactory = [self cellFactoryForIndexPath:indexPath];
    return [cellFactory heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [tableData sectionCount] > 1 ? 22 : 0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([tableData sectionCount] == 1) {
        return nil;
    }
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 1, tableView.frame.size.width, 18)];
    [label setFont:[UIFont boldSystemFontOfSize:14]];
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    [label setText:title];
    label.backgroundColor = [UIColor clearColor];
    if (sectionTitleColor) {
        label.textColor = sectionTitleColor;
    }
    [view addSubview:label];
    if (sectionTitleBackgroundColor) {
        view.backgroundColor = sectionTitleBackgroundColor;
    }
    return view;
}

- (EPTableViewCellFactory *)cellFactoryForIndexPath:(NSIndexPath *)indexPath {
    NSString *displayMode = [self displayModeForIndexPath:indexPath];
    EPTableViewCellFactory *cellFactory = (EPTableViewCellFactory *)[cellFactoriesByDisplayMode valueForKey:displayMode];
    if (!cellFactory) {
        cellFactory = defaultFactory;
    }
    return cellFactory;
}

- (NSString *)displayModeForIndexPath:(NSIndexPath *)indexPath {
    return @"default";
}

- (NSIndexPath *)indexPathForFirstRowWithDisplayMode:(NSString *)displayMode {
    for (NSInteger section = 0; section < [self.tableView numberOfSections]; section++) {
        for (NSInteger row = 0; row < [self.tableView numberOfRowsInSection:section]; row++) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:section];
            if ([displayMode isEqualToString:[self displayModeForIndexPath:path]]) {
                return path;
            }
        }
    }
    return nil;
}

- (void)filterByFavourites:(BOOL)showFavourites {
    [tableData filterWithBlock:^BOOL (NSDictionary *row) {
        return ValueAsBoolean(row, @"favourite") == showFavourites;
    }];
    [self.tableView reloadData];
    if (filterByFavouritesMessage) {
        [self showToast:filterByFavouritesMessage];
    }
}

- (void)clearFilter {
    [tableData clearFilter];
    [self.tableView reloadData];
    if (clearFilterMessage) {
        [self showToast:clearFilterMessage];
    }
}

- (void)loadContent {
    IFResource *rsc = [configuration getValueAsResource:@"data"];
    if (rsc) {
        [self loadContentFromResource:rsc];
    }
}

- (void)loadContentFromResource:(IFResource *)resource {
    [super loadContentFromResource:resource];
    [tableData setData:[resource asJSONData]];
    [self.tableView reloadData];
}

- (void)setContentResource:(IFResource *)resource {
    [super setContentResource:resource];
    defaultFactory.baseResource = resource;
    for (NSString* key in cellFactoriesByDisplayMode) {
        EPTableViewCellFactory *factory = (EPTableViewCellFactory *)[cellFactoriesByDisplayMode valueForKey:key];
        factory.baseResource = resource;
    }
}

- (id)handleEPEvent:(EPEvent *)event {
    id result = [EPEvent notHandledResult];
    if ([event.name hasPrefix:EPEventPrefix]) {
        NSString *action = [event.name substringFromIndex:[EPEventPrefix length]];
        if ([@"filter-by-favourites" isEqualToString:action]) {
            [self filterByFavourites:YES];
        }
        else if ([@"clear-filter" isEqualToString:action]) {
            [self clearFilter];
        }
        result = nil;
    }
    if ([EPEvent isNotHandled:result]) {
        result = [super handleEPEvent:event];
    }
    return result;
}

#pragma mark - Non-public methods

- (void)hideSearchBar {
    if (![tableData isEmpty]) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

#pragma mark - Content Filtering
- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope {
    [tableData filterBy:searchText scope:scope];
}

- (void)reloadDataWithCompletion:(void(^)(void))completionBlock {
    [self.tableView reloadData];
    [self hideSearchBar];
    if(completionBlock) {
        completionBlock();
    }
}

#pragma mark - UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    NSInteger idx = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
    NSString *scope = [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:idx];
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:scope];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    NSString *scope = [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption];
    // Tells the table data source to reload when scope bar selection changes
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:scope];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [tableData clearFilter];
    [self.tableView reloadData];
    [self hideSearchBar]; // TODO: This doesn't seem to work here for some reason...
}

@end
