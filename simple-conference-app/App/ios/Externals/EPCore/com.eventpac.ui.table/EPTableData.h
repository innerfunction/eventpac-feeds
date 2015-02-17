//
//  EPTableData.h
//  EventPacComponents
//
//  Created by Julian Goacher on 08/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "IFJSONData.h"
#import "EPConfiguration.h"
#import "EPValues.h"
#import "ISO8601DateFormatter.h"

@class EPTableData;

@protocol EPTableDataDelegate

- (id)resolveTableDataSectionTitle:(NSDictionary *)section tableData:(EPTableData *)tableData;
- (id)resolveTableDataRef:(NSString *)ref on:(NSDictionary *)cellData tableData:(EPTableData *)tableData;

@end

typedef BOOL (^EPTableDataFilterBlock) (NSDictionary *row);

// Class for accessing a JSON data array as a table data source.
// Uses JS style dotted path data references and NSIndexPaths to resolve
// data on the array.
@interface EPTableData : IFJSONData {
    // The table data. Either an array or cell data dictionaries; or an array of
    // section arrays of cell data dictionaries.
    //NSArray *_data;
    // The currently visible data, i.e. after a filter has been applied.
    NSArray *visibleData;
    // Array of section header titles.
    NSArray *sectionHeaderTitles;
    // A flag indicating whether the data is grouped.
    BOOL isGrouped;
    // An ISO date parser.
    ISO8601DateFormatter *dateParser;
}

// Array of field names which the search filter will be applied to.
@property (nonatomic, strong) NSArray *searchFieldNames;
// A delegate for modifying how data is resolved.
@property (nonatomic, strong) id<EPTableDataDelegate> delegate;
// An array of data for table rows.
@property (nonatomic, strong) NSArray *data;

// Return an EPTableData object initialized with the specified data.
+ (EPTableData *)withData:(NSArray*)data;
// Get cell data for the specified path.
- (NSDictionary *)dataForPath:(NSIndexPath *)path;
// Test whether the data is empty - i.e. contains no rows.
- (BOOL)isEmpty;
// Return the number of sections in the table data.
- (NSInteger)sectionCount;
// Return the number of rows in the specified section.
- (NSInteger)sectionSize:(NSInteger)section;
// Return a title for the specified section.
- (NSString *)sectionTitle:(NSInteger)section;
// Filter the table data by applying a search term.
- (void)filterBy:(NSString *)searchTerm scope:(NSString *)scope;
// Filter the table data using a block.
- (void)filterWithBlock:(EPTableDataFilterBlock)filterTest;
// Clear any filter currently applied to the table data.
- (void)clearFilter;
// Return the index path of the first row with the specified field name set to the specified value.
- (NSIndexPath *)pathForRowWithValue:(NSString *)value forField:(NSString *)name;

@end

@interface NSDictionary (EPTableDataRow) <EPValues>

@end
