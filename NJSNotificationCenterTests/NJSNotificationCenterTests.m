//
//  NJSNotificationCenterTests.m
//  NJSNotificationCenterTests
//
//  Created by Niklas Saers on 9/29/13.
//  Copyright (c) 2013 Niklas Saers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NJSNotificationCenter.h"

@interface NJSNotificationCenterTests : XCTestCase

@end

@implementation NJSNotificationCenterTests {
    NJSNotificationCenter *nc;
}

- (void)setUp
{
    [super setUp];

    nc = [NJSNotificationCenter defaultCenter];

}

- (void)tearDown
{
    XCTAssertTrue([[nc listObservers] count] == 0, @"At end of test, all observers should be removed");
    
    [super tearDown];
}

- (void) completeTest:(NSNotification*) notification {
    NSLog(@"Notification was %p", notification);
}

- (void)testExample
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [nc addObserver:self selector:@selector(completeTest:) name:testNotification object:@3];
    [nc postNotificationName:testNotification object:@3];
    NSLog(@"%@", [nc listObservers]);
    [nc removeObserver:self];
}

@end
