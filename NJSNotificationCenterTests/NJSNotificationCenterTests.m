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

@implementation NJSNotificationCenterTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) completeTest:(NSNotification*) notification {
    NSLog(@"Notification was %p", notification);
}

- (void)testExample
{
    NSString *testNotification = @"TESTNOTIFICATION";
    NJSNotificationCenter *nc = [NJSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(completeTest:) name:testNotification object:@3];
    [nc postNotificationName:testNotification object:@3];
}

@end
