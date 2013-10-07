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

- (void) dontExpect:(BOOL (^)())whileTest assert:(void (^)())assertTest before:(NSInteger) seconds {
    
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
    
    XCTAssertFalse(stop, @"Should not have succeeded for X seconds");
    
    if(assertTest)
        assertTest();
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

#pragma mark - Synchronous tests
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

- (void) testNotificationsWithBlocks
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        
        testResult = @4;
    } name:testNotification object:@5 async:NO];
    [nc postNotificationName:testNotification object:@5];
    
    [self expect:^BOOL{
        return testResult != nil;
    } assert:^{
        XCTAssertEqualObjects(@4, testResult, @"Test result from the notification should be 3");
    } before:5];
    
    
    [nc removeObserver:self];
}

// Very similar to "-(void)testNotificationsWithBlocks", but listens to a different object than the one that subscribes to the notification
- (void) testNotificationsWithBlocks_doesNotReachObjectsNotListenedFor
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        
        testResult = @6;
    } name:testNotification object:@7 async:NO];
    [nc postNotificationName:testNotification object:@8];
    
    [self dontExpect:^BOOL{
        return testResult != nil;
    } assert:^{
        XCTAssertNotEqualObjects(@7, testResult, @"Test result from the notification should NOT be 7");
    } before:5];
    
    [nc removeObserver:self];
}

- (void) testNotificationsWithBlocks_observerWithoutObject_notificationWithObject
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        
        testResult = @9;
    } name:testNotification object:nil async:NO];
    [nc postNotificationName:testNotification object:@10];
    
    [self dontExpect:^BOOL{
        return testResult != nil;
    } assert:^{
        XCTAssertNotEqualObjects(@9, testResult, @"Test result from the notification should be 9");
    } before:5];
    
    
    [nc removeObserver:self];
}

- (void) testNotificationsWithBlocks_observerWithObject_notificationWithoutObject
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        
        testResult = @11;
    } name:testNotification object:@12 async:NO];
    [nc postNotificationName:testNotification object:nil];
    
    [self expect:^BOOL{
        return testResult != nil;
    } assert:^{
        XCTAssertEqualObjects(@11, testResult, @"Test result from the notification should be 11");
    } before:5];
    
    
    [nc removeObserver:self];
}


#pragma mark - Async tests
- (void)testNotificationsWithBlocks_async
{
    NSString *testNotification = @"TESTNOTIFICATION";
    static const NSString *testNotificationKey = @"test";
    
    __weak NJSNotificationCenterTests *weakSelf = self;
    [nc addObserver:self block:^(NSNotification *notification) {
        __strong NJSNotificationCenterTests *strongSelf = weakSelf;
        if(strongSelf != nil) {
            NSDictionary *userInfo = notification.userInfo;
            XCTAssertEqualObjects(@2, (NSNumber*) userInfo[testNotificationKey], @"Notification test value for notification should be 2"); // I really can't spot the capturing of self here
            strongSelf->testResult = @2;
        }
    } name:testNotification object:@3 async:YES priority:10];

    [nc postNotificationName:testNotification object:@3 userInfo:@{ testNotificationKey: @2 } async:YES];
    
    [self expect:^BOOL{
        return testResult != nil;
    } assert:^{
        XCTAssertEqualObjects(@2, testResult, @"Test result from the notification should be 2");
    } before:5];
    
    
    [nc removeObserver:self];
}

- (void)testNotificationWorksLikeItUsedTo_async
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [nc addObserver:self selector:@selector(completeTest:) name:testNotification object:@12];
    [nc postNotificationName:testNotification object:@12 async:YES];
    
    [self expect:^BOOL{
        return testResult != nil;
    } assert:^{
        XCTAssertEqualObjects(@1, testResult, @"Test result from the notification should be 1");
    } before:5];
    
    
    [nc removeObserver:self];
}

// Very similar to "-(void)testNotificationsWithBlocks_async", but listens to a different object than the one that subscribes to the notification
- (void) testNotificationsWithBlocks_doesNotReachObjectsNotListenedFor_async
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        
        testResult = @13;
    } name:testNotification object:@14 async:YES];
    [nc postNotificationName:testNotification object:@15];
    
    [self dontExpect:^BOOL{
        return testResult != nil;
    } assert:^{
        XCTAssertNotEqualObjects(@14, testResult, @"Test result from the notification should NOT be 14");
    } before:5];
    
    [nc removeObserver:self];
}

- (void) testNotificationsWithBlocks_observerWithoutObject_notificationWithObject_async
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        
        testResult = @16;
    } name:testNotification object:nil async:YES];
    [nc postNotificationName:testNotification object:@17];
    
    [self dontExpect:^BOOL{
        return testResult != nil;
    } assert:^{
        XCTAssertNotEqualObjects(@16, testResult, @"Test result from the notification should be 16");
    } before:5];
    
    
    [nc removeObserver:self];
}

- (void) testNotificationsWithBlocks_observerWithObject_notificationWithoutObject_async
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        
        testResult = @18;
    } name:testNotification object:@19 async:YES];
    [nc postNotificationName:testNotification object:nil];
    
    [self expect:^BOOL{
        return testResult != nil;
    } assert:^{
        XCTAssertEqualObjects(@18, testResult, @"Test result from the notification should be 18");
    } before:5];
    
    
    [nc removeObserver:self];
}


@end
