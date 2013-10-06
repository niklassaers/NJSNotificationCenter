//
//  NJSNotificationCenterTests.m
//  NJSNotificationCenterTests
//
//  Created by Niklas Saers on 9/29/13.
//  Copyright (c) 2013 Niklas Saers. See License file for details.
//

#import <XCTest/XCTest.h>
#import "NJSNotificationCenter.h"

@interface NJSNotificationCenterTests : XCTestCase

@end

@implementation NJSNotificationCenterTests {
    NJSNotificationCenter *nc;
    
    NSNumber *testResult;
}

- (void)setUp
{
    [super setUp];

    nc = [NJSNotificationCenter defaultCenter];
    testResult = nil;

}

- (void)tearDown
{
    XCTAssertTrue([[nc listObservers] count] == 0, @"At end of test, all observers should be removed");
    
    [super tearDown];
}

- (void) completeTest:(NSNotification*) notification {
    XCTAssertNotNil(notification, @"The notification received should not be nil");
    
    testResult = @1;
}

- (void) expect:(BOOL (^)())whileTest assert:(void (^)())assertTest before:(NSInteger) seconds {
    
    BOOL stop = NO;
    NSDate *until = [NSDate dateWithTimeIntervalSinceNow:seconds];
    while ([until timeIntervalSinceNow] > 0 && !stop)
    {
        NSDate *deltaUntil = [NSDate dateWithTimeIntervalSinceNow:1.f/10];
        
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:deltaUntil];
        
        if(whileTest != nil)
            stop = whileTest();
    }
    
    XCTAssertTrue(stop, @"Should have been stopped within X seconds");
    
    if(assertTest)
        assertTest();
}

- (void)testNotificationWorksLikeItUsedTo
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [nc addObserver:self selector:@selector(completeTest:) name:testNotification object:@3];
    [nc postNotificationName:testNotification object:@3];

    [self expect:^BOOL{
        return testResult != nil;
    } assert:^{
        XCTAssertEqualObjects(@1, testResult, @"Test result from the notification should be 1");
    } before:5];


    [nc removeObserver:self];
}

- (void)testNotificationAsync
{
    NSString *testNotification = @"TESTNOTIFICATION";
    
    [nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertEqualObjects(@2, (NSNumber*) notification.userInfo[@"test"], @"Notification test value for notification should be 2");
        testResult = @2;
    } name:testNotification object:@3 async:YES priority:10];

    [nc postNotificationName:testNotification object:@3 userInfo:@{ @"test": @2 } async:YES];
    
    [self expect:^BOOL{
        return testResult != nil;
    } assert:^{
        XCTAssertEqualObjects(@2, testResult, @"Test result from the notification should be 2");
    } before:5];
    
    
    [nc removeObserver:self];
}


@end
