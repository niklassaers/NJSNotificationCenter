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
    NJSNotificationCenter *_nc;
    
    NSNumber *_testResult;
}

- (void)setUp
{
    [super setUp];

    _nc = [NJSNotificationCenter defaultCenter];
    _testResult = nil;

}

- (void)tearDown
{
    XCTAssertTrue([[_nc listObservers] count] == 0, @"At end of test, all observers should be removed");
    
    [super tearDown];
}

- (void) completeTest:(NSNotification*) notification {
    XCTAssertNotNil(notification, @"The notification received should not be nil");
    
    _testResult = @1;
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
    [_nc addObserver:self selector:@selector(completeTest:) name:testNotification object:@3];
    [_nc postNotificationName:testNotification object:@3];

    [self expect:^BOOL{
        return _testResult != nil;
    } assert:^{
        XCTAssertEqualObjects(@1, _testResult, @"Test result from the notification should be 1");
    } before:5];


    [_nc removeObserver:self];
}

- (void) testNotificationsWithBlocks
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [_nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        
        _testResult = @4;
    } name:testNotification object:@5 async:NO];
    [_nc postNotificationName:testNotification object:@5];
    
    [self expect:^BOOL{
        return _testResult != nil;
    } assert:^{
        XCTAssertEqualObjects(@4, _testResult, @"Test result from the notification should be 3");
    } before:5];
    
    
    [_nc removeObserver:self];
}

// Very similar to "-(void)testNotificationsWithBlocks", but listens to a different object than the one that subscribes to the notification
- (void) testNotificationsWithBlocks_doesNotReachObjectsNotListenedFor
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [_nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        
        _testResult = @6;
    } name:testNotification object:@7 async:NO];
    [_nc postNotificationName:testNotification object:@8];
    
    [self dontExpect:^BOOL{
        return _testResult != nil;
    } assert:^{
        XCTAssertNotEqualObjects(@7, _testResult, @"Test result from the notification should NOT be 7");
    } before:5];
    
    [_nc removeObserver:self];
}

- (void) testNotificationsWithBlocks_observerWithoutObject_notificationWithObject
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [_nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        
        _testResult = @9;
    } name:testNotification object:nil async:NO];
    [_nc postNotificationName:testNotification object:@10];
    
    [self dontExpect:^BOOL{
        return _testResult != nil;
    } assert:^{
        XCTAssertNotEqualObjects(@9, _testResult, @"Test result from the notification should be 9");
    } before:5];
    
    
    [_nc removeObserver:self];
}

- (void) testNotificationsWithBlocks_observerWithObject_notificationWithoutObject
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [_nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        
        _testResult = @11;
    } name:testNotification object:@12 async:NO];
    [_nc postNotificationName:testNotification object:nil];
    
    [self expect:^BOOL{
        return _testResult != nil;
    } assert:^{
        XCTAssertEqualObjects(@11, _testResult, @"Test result from the notification should be 11");
    } before:5];
    
    
    [_nc removeObserver:self];
}

- (void) testNotificationsWithBlocks_ordered
{
    NSString *testNotification = @"TESTNOTIFICATION";
    NSString *o1 = @"Observer #1", *o2 = @"Observer #2", *o3 = @"Observer #3";
    [_nc addObserver:o1 block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        XCTAssertNil(_testResult, @"_testResult should be nil at this point");
        _testResult = @19;
    } name:testNotification object:@22 async:NO priority:0];
    
    [_nc addObserver:o2 block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        XCTAssertEqualObjects(@19, _testResult, @"_testResult should be 19, thus following priority 0");
        _testResult = @20;
    } name:testNotification object:@23 async:NO priority:10];
    [_nc addObserver:o3 block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        XCTAssertEqualObjects(@20, _testResult, @"_testResult should be 20, thus following priority 10");
        _testResult = @21;
    } name:testNotification object:@24 async:NO priority:20];
    [_nc postNotificationName:testNotification object:nil];
    
    [self expect:^BOOL{
        return _testResult != nil && [_testResult isEqual:@21];
    } assert:^{
        XCTAssertEqualObjects(@21, _testResult, @"Test result from the notification should be 21");
    } before:5];
    
    
    [_nc removeObserver:o1];
    [_nc removeObserver:o2];
    [_nc removeObserver:o3];
}


#pragma mark - Async tests
- (void)testNotificationsWithBlocks_async
{
    NSString *testNotification = @"TESTNOTIFICATION";
    static const NSString *testNotificationKey = @"test";
    
    __weak NJSNotificationCenterTests *weakSelf = self;
    [_nc addObserver:self block:^(NSNotification *notification) {
        __strong NJSNotificationCenterTests *strongSelf = weakSelf;
        if(strongSelf != nil) {
            NSDictionary *userInfo = notification.userInfo;
            XCTAssertEqualObjects(@2, (NSNumber*) userInfo[testNotificationKey], @"Notification test value for notification should be 2"); // I really can't spot the capturing of self here
            strongSelf->_testResult = @2;
        }
    } name:testNotification object:@3 async:YES priority:10];

    [_nc postNotificationName:testNotification object:@3 userInfo:@{ testNotificationKey: @2 } async:YES];
    
    [self expect:^BOOL{
        return _testResult != nil;
    } assert:^{
        XCTAssertEqualObjects(@2, _testResult, @"Test result from the notification should be 2");
    } before:5];
    
    
    [_nc removeObserver:self];
}

- (void)testNotificationWorksLikeItUsedTo_async
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [_nc addObserver:self selector:@selector(completeTest:) name:testNotification object:@12];
    [_nc postNotificationName:testNotification object:@12 async:YES];
    
    [self expect:^BOOL{
        return _testResult != nil;
    } assert:^{
        XCTAssertEqualObjects(@1, _testResult, @"Test result from the notification should be 1");
    } before:5];
    
    
    [_nc removeObserver:self];
}

// Very similar to "-(void)testNotificationsWithBlocks_async", but listens to a different object than the one that subscribes to the notification
- (void) testNotificationsWithBlocks_doesNotReachObjectsNotListenedFor_async
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [_nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        
        _testResult = @13;
    } name:testNotification object:@14 async:YES];
    [_nc postNotificationName:testNotification object:@15];
    
    [self dontExpect:^BOOL{
        return _testResult != nil;
    } assert:^{
        XCTAssertNotEqualObjects(@14, _testResult, @"Test result from the notification should NOT be 14");
    } before:5];
    
    [_nc removeObserver:self];
}

- (void) testNotificationsWithBlocks_observerWithoutObject_notificationWithObject_async
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [_nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        
        _testResult = @16;
    } name:testNotification object:nil async:YES];
    [_nc postNotificationName:testNotification object:@17];
    
    [self dontExpect:^BOOL{
        return _testResult != nil;
    } assert:^{
        XCTAssertNotEqualObjects(@16, _testResult, @"Test result from the notification should be 16");
    } before:5];
    
    
    [_nc removeObserver:self];
}

- (void) testNotificationsWithBlocks_observerWithObject_notificationWithoutObject_async
{
    NSString *testNotification = @"TESTNOTIFICATION";
    [_nc addObserver:self block:^(NSNotification *notification) {
        XCTAssertNotNil(notification, @"The notification received should not be nil"); // How does this capture self?
        
        _testResult = @18;
    } name:testNotification object:@19 async:YES];
    [_nc postNotificationName:testNotification object:nil];
    
    [self expect:^BOOL{
        return _testResult != nil;
    } assert:^{
        XCTAssertEqualObjects(@18, _testResult, @"Test result from the notification should be 18");
    } before:5];
    
    
    [_nc removeObserver:self];
}


@end
