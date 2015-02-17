//
//  EPTableData.m
//  EventPacComponents
//
//  Created by Julian Goacher on 08/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "EPTableData.h"
#import "ISO8601DateFormatter.h"
#import "IFTypeConversions.h"
#import "objc/runtime.h"

// TODO: Add methods for filtering and indexing data.
// x. Add a method for applying a filter to the data. Should replace the data property
//    with a filtered copy of the data. Add a method for clearing the applied filter which
//    restores the original data property.
// 2. Add a method for returning an a-z index of the current data.
// Note that both methods have a dependancy on the structure of the data - i.e. they need
// to know something about the data format in order to operate. So either the data should
// provide standard properties for inspecting the data in order to filter and index; or
// the class should be configured with the information; or do both.

// 20140202 - Changes to internal structure:
// The internal strucuture has been refactored to use a couple of NSDictionary categories which
// provide (1) a method for resolving JSON refs on a dictionary (taken from JSONData); and (2)
// methods for resolving typed values on the dictionary data using JSON refs. This has been done
// to support a modified way of looking up table data. Instead of the old method, which resolved
// the data row each time a data property was looked up, the data row is resolved once and each
// data property is then read from the result. The result is returned as an NSDictionary category,
// with the type specific access methods - e.g. getDate, getNumber etc. - being implemented
// by the category (see code at end of this file).

@implementation EPTableData

@synthesize searchFieldNames;

- (id)init {
    self = [super init];
    if (self) {
        // Initialize the object with an empty data array.
        _data = [NSArray array];
        visibleData = _data;
        isGrouped = false;
        self.searchFieldNames = [NSArray arrayWithObjects:@"title", @"description", nil];
        dateParser = [[ISO8601DateFormatter alloc] init];
    }
    return self;
}

+ (EPTableData *)withData:(NSArray *)data {
    EPTableData *tableData = [[EPTableData alloc] init];
    [tableData setData:data];
    return tableData;
}

// Set the table data.
- (void)setData:(NSArray *)data {
    // Test whether the data is grouped or non-grouped. If grouped, then extract section header titles from the data.
    // This method allows grouped data to be presented in one of two ways, and assumes that the data is grouped
    // consistently throughout.
    // * The first grouping format is as an array of arrays. The section header title is extracted as the first character
    // of the title of the first item in each group.
    // * The second grouping format is as an array of dictionaries. Each dictionary represents a section object with
    // 'sectionTitle' and 'sectionData' properties.
    // Data can also be presented as an array of strings, in which case each string is used as a row title.
    id firstItem = [data count] > 0 ? [data objectAtIndex:0] : nil;
    if ([firstItem isKindOfClass:[NSArray class]]) {
        isGrouped = YES;
        NSMutableArray *titles = [[NSMutableArray alloc] initWithCapacity:[data count]];
        for (NSArray *section in data) {
            NSDictionary *row = [section objectAtIndex:0];
            if (row) {
                // TODO: Should use getValueAsString here?
                [titles addObject:[(NSString*)[row valueForKey:@"title"] substringToIndex:1]];
            }
            else {
                [titles addObject:@""];
            }
        }
        _data = data;
        sectionHeaderTitles = titles;
    }
    else if([firstItem isKindOfClass:[NSDictionary class]]) {
        // TODO: Use hasValue, getValueAsString methods?
        if ([firstItem valueForKey:@"sectionTitle"] || [firstItem valueForKey:@"sectionData"]) {
            isGrouped = YES;
            NSMutableArray *titles = [[NSMutableArray alloc] initWithCapacity:[data count]];
            NSMutableArray *sections = [[NSMutableArray alloc] initWithCapacity:[data count]];
            for (NSDictionary *section in data) {
                NSString *sectionTitle = [self.delegate resolveTableDataSectionTitle:section tableData:self];
                if (sectionTitle == nil) {
                    sectionTitle = [section valueForKey:@"sectionTitle"];
                }
                [titles addObject:(sectionTitle ? sectionTitle : @"")];
                NSArray *sectionData = [section valueForKey:@"sectionData"];
                [sections addObject:(sectionData ? sectionData : [NSArray array])];
            }
            _data = sections;
            sectionHeaderTitles = titles;
        }
        else {
            isGrouped = NO;
            _data = data;
        }
    }
    else if([firstItem isKindOfClass:[NSString class]]) {
        isGrouped = NO;
        NSMutableArray *rows = [[NSMutableArray alloc] initWithCapacity:[data count]];
        for (NSString *title in data) {
            NSDictionary *row = [NSDictionary dictionaryWithObjectsAndKeys:title, @"title", nil];
            [rows addObject:row];
        }
        _data = rows;
    }
    else {
        isGrouped = NO;
        _data = [NSArray array];
    }
    visibleData = _data;
}

// Get cell data for the specified path.
- (NSDictionary *)dataForPath:(NSIndexPath *)path {
    // Resolve the cell data. First check the type of the first data item.
    // - If data is empty then result will be nil.
    // - If first data item is an NSArray then we're dealing with a grouped list (i.e. with sections).
    // - Else we are dealing with non-grouped data.
    NSDictionary *cellData = nil;
    if ([visibleData count] > 0) {
        if (isGrouped) {
            if ([visibleData count] > path.section) {
                NSArray *sectionData = [visibleData objectAtIndex:path.section];
                if ([sectionData count] > path.row) {
                    cellData = [sectionData objectAtIndex:path.row];
                }
            }
        }
        else if ([visibleData count] > path.row) {
            cellData = [visibleData objectAtIndex:path.row];
        }
    }
    return cellData;
}

- (BOOL)isEmpty {
    // TODO: A more complete implementation would take accout of grouped data with multiple empty sections.
    return [_data count] == 0;
}

// Return the number of sections in the table data.
- (NSInteger)sectionCount {
    if ([visibleData count] > 0) {
        return isGrouped ? [visibleData count] : 1;
    }
    return 0;
}

- (NSString *)sectionTitle:(NSInteger)section {
    return [sectionHeaderTitles objectAtIndex:section];
}

// Return the number of rows in the specified section.
- (NSInteger)sectionSize:(NSInteger)section {
    NSInteger size = 0;
    if ([visibleData count] > 0) {
        if (isGrouped) {
            // If first item is an array then we have grouped data, return the size of the section
            // array if it exists, else 0.
            if ([visibleData count] > section) {
                NSArray *sectionArray = [visibleData objectAtIndex:section];
                size = [sectionArray count];
            }
            else {
                size = 0;
            }
        }
        else if (section == 0) {
            // We don't have grouped data, but if the required section is 0 then this corresponds to the
            // data array in a non-grouped data set.
            size = [visibleData count];
        }
    }
    return size;
}

- (void)filterBy:(NSString *)searchTerm scope:(NSString *)scope {
    NSArray *searchNames = scope ? [NSArray arrayWithObject:scope] : self.searchFieldNames;
    EPTableDataFilterBlock filterTest = ^(NSDictionary *row) {
        for (NSString *name in searchNames) {
            NSString *value = [row valueForKey:name];
            if (value && [value rangeOfString:searchTerm options:NSCaseInsensitiveSearch].location != NSNotFound) {
                return YES;
            }
        }
        return NO;
    };
    [self filterWithBlock:filterTest];
}

- (void)filterWithBlock:(EPTableDataFilterBlock)filterTest {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (isGrouped) {
        for (NSArray *section in _data) {
            NSMutableArray *filteredSection = [[NSMutableArray alloc] init];
            for (NSDictionary *row in section) {
                if (filterTest(row)) {
                    [filteredSection addObject:row];
                }
            }
            [result addObject:filteredSection];
        }
    }
    else {
        for (NSDictionary *row in _data) {
            if (filterTest(row)) {
                [result addObject:row];
            }
        }
    }
    visibleData = result;
}

- (void)clearFilter {
    visibleData = _data;
}

- (NSIndexPath *)pathForRowWithValue:(NSString *)value forField:(NSString *)name {
    if (isGrouped) {
        for (NSUInteger s = 0; s < [_data count]; s++) {
            NSArray *section = [_data objectAtIndex:s];
            for (NSUInteger r = 0; r < [section count]; r++) {
                NSDictionary *row = [section objectAtIndex:r];
                if ([value isEqualToString:[[row objectForKey:name] description]]) {
                    return [NSIndexPath indexPathForRow:r inSection:s];
                }
            }
        }
    }
    else {
        for (NSUInteger r = 0; r < [_data count]; r++) {
            NSDictionary *row = [_data objectAtIndex:r];
            // NOTE: Compare using the string value of the target field, so that numeric values specified
            // as a string will match.
            if ([value isEqualToString:[[row objectForKey:name] description]]) {
                return [NSIndexPath indexPathForRow:r inSection:0];
            }
        }
    }
    return nil;
}

@end

@implementation NSDictionary (EPTableDataRow)

- (id)getValue:(NSString *)name {
    return [IFJSONData resolvePath:name onData:self];
}

- (BOOL)hasValue:(NSString *)name {
    return [self getValue:name] != nil;
}

// Return a list of the top-level names in the values object.
- (NSArray *)getValueNames {
    return [self allKeys];
}

// Return the type of the specified value.
- (EPValueType)getValueType:(NSString *)name {
    id value = [self getValue:name];
    if (value == nil)                           return EPValueTypeUndefined;
    // NOTE: Can't reliably detect boolean here, as boolean values are represented using NSNumber.
    if ([value isKindOfClass:[NSNumber class]]) return EPValueTypeNumber;
    if ([value isKindOfClass:[NSString class]]) return EPValueTypeString;
    if ([value isKindOfClass:[NSArray class]])  return EPValueTypeList;
    return EPValueTypeObject;
}

// Resolve a string value on the row data.
- (NSString *)getValueAsString:(NSString *)name {
    return [self getValueAsString:name defaultValue:nil];
}

// Resolve a string value on the row data, return the default value if not set.
- (NSString *)getValueAsString:(NSString *)name defaultValue:(NSString *)defaultValue {
    NSString *value = [IFTypeConversions asString:[self getValue:name]];
    return value == nil ? defaultValue : value;
}

- (NSString *)getValueAsLocalizedString:(NSString *)name {
    NSString *value = [self getValueAsString:name];
    return value == nil ? @"" : NSLocalizedString(value, @"");
}

// Resolve a number value on the row data.
- (NSNumber *)getValueAsNumber:(NSString *)name {
    return [self getValueAsNumber:name defaultValue:nil];
}

// Resolve a number value on the row data, return the default value if not set.
- (NSNumber *)getValueAsNumber:(NSString *)name defaultValue:(NSNumber *)defaultValue {
    NSNumber *value = [IFTypeConversions asNumber:[self getValue:name]];
    return value == nil ? defaultValue : value;
}

// Resolve a boolean value on the row data.
- (BOOL)getValueAsBoolean:(NSString *)name {
    return [self getValueAsBoolean:name defaultValue:NO];
}

// Resolve a boolean value on the row data, return the default value if not set.
- (BOOL)getValueAsBoolean:(NSString *)name defaultValue:(BOOL)defaultValue {
    return [self hasValue:name] ? [IFTypeConversions asBoolean:[self getValue:name]] : defaultValue;
}

// Return the named property as a date value.
- (NSDate *)getValueAsDate:(NSString *)name {
    return [self getValueAsDate:name defaultValue:nil];
}

- (NSDate *)getValueAsDate:(NSString *)name defaultValue:(NSDate *)defaultValue {
    NSDate *value = [IFTypeConversions asDate:[self getValue:name]];
    return value == nil ? defaultValue : value;
}

// Return the named property as a colour value.
- (UIColor *)getValueAsColor:(NSString *)name {
    return [self getValueAsColor:name defaultValue:0];
}

- (UIColor *)getValueAsColor:(NSString *)name defaultValue:(UIColor *)defaultValue {
    UIColor *color = [self getValueAsColor:name];
    return color ? color : defaultValue;
}

// Return the named property as a URL.
- (NSURL *)getValueAsURL:(NSString *)name {
    return [IFTypeConversions asURL:[self getValue:name]];
}

// Return the named property as data.
- (NSData *)getValueAsData:(NSString *)name {
    return [IFTypeConversions asData:[self getValue:name]];
}

// Return the named property as an image.
- (UIImage *)getValueAsImage:(NSString *)name {
    return [IFTypeConversions asImage:[self getValue:name]];
}

@end
