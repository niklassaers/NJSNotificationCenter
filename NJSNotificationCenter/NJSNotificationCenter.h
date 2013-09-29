//
//  NJSNotificationCenter.h
//  NJSNotificationCenter
//
//  Created by Niklas Saers on 9/29/13.
//  Copyright (c) 2013 Niklas Saers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NJSNotificationCenter : NSNotificationCenter

@property (nonatomic, assign) BOOL logAllNotifications;

#pragma mark NSNotificationCenter interface
+ (instancetype)defaultCenter;

- (instancetype)init;	/* designated initializer */

- (void) addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject;

- (void) postNotification:(NSNotification *)notification;
- (void) postNotificationName:(NSString *)aName object:(id)anObject;
- (void) postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;

- (void) removeObserver:(id)observer;
- (void) removeObserver:(id)observer name:(NSString *)aName object:(id)anObject;

- (id) addObserverForName:(NSString *)name object:(id)obj queue:(NSOperationQueue *)queue usingBlock:(void (^)(NSNotification *note))block;

#pragma mark NJSNotificationCenter extra interface

- (void) addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject async:(BOOL)async;
- (void) addObserver:(id)observer block:(void (^)())block name:(NSString *)aName object:(id)anObject async:(BOOL)async;
- (void) addObserverToMainThread:(id)observer block:(void (^)())block name:(NSString *)aName object:(id)anObject async:(BOOL)async;
- (void) addObserverToMainThread:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject async:(BOOL)async;
- (void) addObserver:(id)observer toThread:(NSThread*)thread selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject async:(BOOL)async;
- (void) addObserver:(id)observer toThread:(NSThread*)thread block:(void (^)())block name:(NSString *)aName object:(id)anObject async:(BOOL)async;

- (void) postNotification:(NSNotification *)notification async:(BOOL)async;
- (void) postNotificationName:(NSString *)aName object:(id)anObject async:(BOOL)async;
- (void) postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo async:(BOOL)async;


@end
