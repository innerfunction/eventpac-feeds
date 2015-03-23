//
//  EPTableViewController.h
//  EventPacComponents
//
//  Created by Julian Goacher on 07/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "EPConfiguration.h"
#import "EPTableData.h"
#import "EPTableViewCellFactory.h"
#import "EPComponent.h"
#import "EPEventHandler.h"

// A basic table view component.
// Recognized configuration keys are:
// * tableStyle:    "Grouped" or "Plain"; see UITableViewStyle.
// * rowStyle:     The default table cell style. See values for table cell 'style' property described below.
// * rowBackgroundImage:
// * rowSelectedBackgroundImage:
// * rowHeight
//
// Implements the EPContentView protocol and accepts array data in two formats, depending on the table style.
// * Plain tables:   Data should be an NSArray of table cell data.
// * Grouped tables: Data should be an NSArray of table sections, where each section is an NSArray of table cell data.
//
// Each table cell data item must be an NSDictionary with the following properties:
// * title:             The main text displayed on the cell.
// * description:       Additional text displayed below the title (Optional).
// * image:             URI of an image to display on the LHS of the cell (Optional).
// * accessory:         Type of the accessory view displayed on the RHS of the cell (Optional).
//                      Takes the following values, corresponding to the values defined for UITableViewCellAccessoryType:
//                      + None
//                      + DisclosureIndicator
//                      + DetailButton
//                      + Checkmark
// * style:             The cell style. Overrides the style specified in the configuration when supplied (Optional).
//                      Has the following values, corresponding to the values defined by UITableViewCellStyle:
//                      + Default
//                      + Style1
//                      + Style2
//                      + Subtitle
// * backgroundImage:   URI of the cell background image. Overrides any value specified in the configuration. (Optional).
// * selectedBackgroundImage: URI of the cell background image when selected. (Optional).
// * height:            The row height.
// * action:            A dispatch URI which is invoked when a table cell is selected.
@interface EPTableViewController : UITableViewController <UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate, EPComponent, EPEventHandler> {
    UISearchBar *searchBar;
    UISearchDisplayController *searchDisplayController;
    EPConfiguration *configuration;
    EPTableData *tableData;
    IFResource *baseResource;
    id dataObserver;
    NSDictionary *cellFactoriesByDisplayMode;
    EPTableViewCellFactory *defaultFactory;
    UIColor *sectionTitleColor;
    UIColor *sectionTitleBackgroundColor;
    BOOL scrollToSelected;
    NSString *filterByFavouritesMessage;
    NSString *clearFilterMessage;
}

@property (nonatomic, strong) id<EPEventHandler> eventHandler;
@property (nonatomic, strong) NSString *selectedID;

- (void)loadContent;
// Get the table cell factory for the specified row position.
- (EPTableViewCellFactory *)cellFactoryForIndexPath:(NSIndexPath *)indexPath;
// Get the display mode for the table row at the specified position.
- (NSString *)displayModeForIndexPath:(NSIndexPath *)indexPath;
// Get the position of the first table row with the specified display mode.
- (NSIndexPath *)indexPathForFirstRowWithDisplayMode:(NSString *)displayMode;
// Filter the table to only show rows with the specified favourite status.
- (void)filterByFavourites:(BOOL)showFavourites;
// Clear any currently applied table data filter.
- (void)clearFilter;

@end
