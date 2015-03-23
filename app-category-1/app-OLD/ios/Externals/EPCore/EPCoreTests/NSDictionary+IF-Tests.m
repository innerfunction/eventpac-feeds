//
//  NSDictionary+IF-Tests.m
//  EPCore
//
//  Created by Julian Goacher on 03/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSDictionary+IF.h"

@interface NSDictionary_IF_Tests : XCTestCase {
    NSDictionary *parentDictionary;
}

@end

@implementation NSDictionary_IF_Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    parentDictionary = @{ @"a":@"one", @"b":@"two", @"c":@"three" };
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExtend {
    NSDictionary *dictionary = [parentDictionary extendWith:@{ @"b":@"TWO", @"d":@"four" }];
    if ([dictionary count] != 4) {
        XCTFail(@"Dictionary has %ld entries, should have 4", (unsigned long)[dictionary count]);
    }
    id value = [dictionary objectForKey:@"a"];
    if (![value isEqualToString:@"one"]) {
        XCTFail(@"Value for 'a' has value %@, should be 'one'", value);
    }
    value = [dictionary objectForKey:@"b"];
    if (![value isEqualToString:@"TWO"]) {
        XCTFail(@"Value for 'b' has value %@, should be 'TWO'", value);
    }
    value = [dictionary objectForKey:@"d"];
    if (![value isEqualToString:@"four"]) {
        XCTFail(@"Value for 'd' has value %@, should be 'four'", value);
    }
}

- (void)testAddedObject {
    NSDictionary *dictionary1 = [parentDictionary dictionaryWithAddedObject:@"five" forKey:@"e"];
    id value = [dictionary1 objectForKey:@"e"];
    if (![value isEqualToString:@"five"]) {
        XCTFail(@"Value for 'e' has value %@, should be 'five'", value);
    }
    NSDictionary *dictionary2 = [dictionary1 dictionaryWithAddedObject:@"six" forKey:@"f"];
    value = [dictionary2 objectForKey:@"f"];
    if (![value isEqualToString:@"six"]) {
        XCTFail(@"Value for 'f' has value %@, should be 'six'", value);
    }
    if (dictionary1 != dictionary2) {
        XCTFail(@"dictionaryWithAddedObject failed to return same mutable instance on second invocation");
    }
}

@end
