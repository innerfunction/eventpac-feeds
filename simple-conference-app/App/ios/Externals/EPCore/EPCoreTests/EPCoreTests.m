//
//  EPCoreTests.m
//  EPCoreTests
//
//  Created by Julian Goacher on 06/02/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EPCore.h"

@interface EPCoreTests : XCTestCase {

}

@end

@implementation EPCoreTests

- (void)setUp
{
    [super setUp];
    // Use the test class bundle as the main bundle: See http://stackoverflow.com/questions/21021227/easiest-way-to-use-bundle-resources-for-testing
    NSBundle *testBundle = [NSBundle bundleForClass:[EPCoreTests class]];
    [EPCore setupWithConfiguration:@"app:configuration.json" mainBundlePath:[testBundle resourcePath]];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEPCoreInstantiation {
    if (![EPCore getCore]) {
        XCTFail(@"EPCore instance not available");
    }
}

- (void)testTypes {
    EPConfiguration *types = [EPCore getCore].types;
    if (!types) {
        XCTFail(@"EPCore.types not available");
    }
    NSString *aliasURISchemeHandlerType = [types getValueAsString:@"AliasURISchemeHandler"];
    if (!aliasURISchemeHandlerType) {
        XCTFail(@"EPCore.types - AliasURISchemeHandler not defined");
    }
    if (![aliasURISchemeHandlerType isEqualToString:@"EPAliasURISchemeHandler"]) {
        XCTFail(@"EPCore.types - AliasURISchemeHandler mapped to incorrect type: %@", aliasURISchemeHandlerType);
    }
}

- (void)testAvailableServices {
}

- (void)testIsEPURIScheme {
    BOOL isEPURIScheme = [[EPCore getCore] isEPURIScheme:@"alias"];
    if (!isEPURIScheme) {
        XCTFail(@"[EPCore isEPURIScheme:alias] failed");
    }
}

- (void)testResolveAliasURI {
    EPCore *epcore = [EPCore getCore];
    IFResource *resource = [epcore resolveURIFromString:@"alias:test"];
    if (!resource) {
        XCTFail(@"alias:test URI not resolved");
    }
    NSString *result = [resource asString];
    if (![result isEqualToString:@"TestAliasIsWorking"]) {
        XCTFail(@"alias:test URI resolved to wrong value: %@", result);
    }
}

- (void)testResolveGlobalsURI {
    EPCore *epcore = [EPCore getCore];
    IFResource *resource = [epcore resolveURIFromString:@"globals:templateContext.defaultPlatform"];
    if (!resource) {
        XCTFail(@"globals:templateContext.defaultPlatform not resolved");
    }
    NSString *result = [resource asString];
    if (![result isEqualToString:@"ios2x"]) {
        XCTFail(@"%@ resolved to wrong value: %@", resource.uri, result);
    }
}

- (void)testDataTypeConversions {
    EPCore *core = [EPCore getCore];
    NSString *svalue = [core.configuration getValueAsString:@"data.string"];
    if (!([svalue isKindOfClass:[NSString class]] && [@"abcdefghij" isEqualToString:svalue])) {
        XCTFail(@"getValueAsString: class=%@ value=%@", [svalue class], svalue);
    }
    NSNumber *nvalue = [core.configuration getValueAsNumber:@"data.number"];
    if (!([nvalue isKindOfClass:[NSNumber class]] && [nvalue integerValue] == 100)) {
        XCTFail(@"getValueAsNumber: class=%@ value=%@", [nvalue class], nvalue);
    }
    BOOL bvalue = [core.configuration getValueAsBoolean:@"data.boolean"];
    if (!bvalue == YES) {
        XCTFail(@"getValueAsBoolean");
    }
    NSDate *dvalue = [core.configuration getValueAsDate:@"data.date"];
    if (!([dvalue isKindOfClass:[NSDate class]] && [@"2014-02-12 19:00:00 +0000" isEqualToString:[dvalue description]])) {
        XCTFail(@"getValueAsDate: class=%@ value=%@", [dvalue class], [dvalue description]);
    }
    /* [UIImage imageNamed won't work in a unit test: http://stackoverflow.com/questions/8602876/accessing-a-uiimage-inside-a-ocunit-test-target
    UIImage *image = [core.configuration getValueAsImage:@"data.image"];
    if (![image isKindOfClass:[UIImage class]]) {
        XCTFail(@"getValueAsImage: class=%@ value=%@", [image class], [image description]);
    }
    */
}

@end
