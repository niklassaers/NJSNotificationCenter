//
//  NJSNotificationCenter.m
//  NJSNotificationCenter
//
//  Created by Niklas Saers on 9/29/13.
//  Copyright (c) 2013 Niklas Saers. See License file for details.
//

#import "NJSNotificationCenter.h"

#pragma mark Dictionary helper methods

@interface NJSNotificationKey : NSObject<NSCopying>
@property (nonatomic, strong) id observer;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) id object;

// Parts that don't compare in the key
@property (nonatomic, copy) NSNumber *runOnMainthread;
@property (nonatomic, copy) NSNumber * runAsync;
@property (nonatomic, strong) NSThread *thread;
@property (nonatomic, assign) NSInteger priority;

- (instancetype) initWithObserver:(id)anObserver name:(NSString*)aName object:(id)anObject;

@end

@implementation NJSNotificationKey
- (instancetype) initWithObserver:(id)anObserver name:(NSString*)aName object:(id)anObject {
    self = [super init];
    if(self != nil) {
        self.observer = anObserver;
        self.name = aName;
        self.object = anObject;
    }
    return self;
}

/**
 * Credit to Jeff Laing - http://stackoverflow.com/questions/19213506/nsmutabledictionary-with-nil-as-value
 */
- (NSUInteger) hash {
    return [self.description hash];
}

- (NSString*) description {
    return [NSString stringWithFormat:@"%p %@ %p", self.observer, self.name, self.object];
}

- (id)copyWithZone:(NSZone *)zone {
    NJSNotificationKey *copy = [[NJSNotificationKey alloc] initWithObserver:self.observer name:self.name object:self.object];
    copy.runOnMainthread = self.runOnMainthread;
    copy.runAsync = self.runAsync;
    copy.thread = self.thread;
    copy.priority = self.priority;
    return copy;
}

- (BOOL) isEqual:(NJSNotificationKey*)other {
    if([self.observer respondsToSelector:@selector(isEqual:)]) {
        if(![self.observer isEqual:other])
            return NO;
    } else if(self.observer != other.observer)
        return NO;
    if([self.object respondsToSelector:@selector(isEqual:)]) {
        if(![self.object isEqual:other])
            return NO;
    } else if(self.object != other.object)
        return NO;
    if(![self.name isEqualToString:other.name])
        return NO;
    return YES;
}

@end

@interface NJSNotificationValue : NSObject
@property (nonatomic, assign) SEL selector;
@property (nonatomic, copy) void (^block)(NSNotification *notification);
- (instancetype) initWithSelector:(SEL) aSelector;
- (instancetype) initWithBlock:(void (^)(NSNotification *notification)) aBlock;
@end

@implementation NJSNotificationValue {
    BOOL _blockBased;
}

- (instancetype) initWithSelector:(SEL) aSelector {
    self = [super init];
    if(self != nil) {
        self.selector = aSelector;
    }
    return self;
}

- (instancetype) initWithBlock:(void (^)(NSNotification *notification)) aBlock {
    self = [super init];
    if(self != nil) {
        self.block = aBlock;
    }
    return self;
}

- (void) setSelector:(SEL)selector {
    _selector = selector;
    _blockBased = NO;
}

- (void) setBlock:(void (^)(NSNotification *notification))block {
    _block = [block copy];
    _blockBased = YES;
}

- (void) selectorForBlock:(NSDictionary*) selectorForBlockArg {
    void (^block)() = selectorForBlockArg[@"block"];
    NSNotification *notification = selectorForBlockArg[@"notification"];
    
    block(notification);
}

- (void) performForKey:(NJSNotificationKey*) key notification:(NSNotification*) notification {
    
    if(_blockBased == YES) {
        void (^block)(NSNotification *notification) = [self.block copy];
        NSDictionary *selectorForBlockArg = @{ @"block": block, @"notification": notification };
        
        if(key.thread != nil)
            [self performSelector:@selector(selectorForBlock:) onThread:key.thread withObject:selectorForBlockArg waitUntilDone:NO];
        else if(key.runOnMainthread != nil && [key.runOnMainthread boolValue] == YES) {
            if(key.runAsync != nil && [key.runAsync boolValue] == YES) {
                dispatch_async(dispatch_get_main_queue(), ^{ block(notification); });
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^{ block(notification); });
            }
        } else if(key.runAsync != nil && [key.runAsync boolValue] == YES) {
            [self performSelectorInBackground:@selector(selectorForBlock:) withObject:selectorForBlockArg];
        } else {
            [self selectorForBlock:selectorForBlockArg];
        }
        
        
    } else { // Selector based
#pragma clang push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        
        SEL selector = self.selector;

        if(key.thread != nil)
            [key.observer performSelector:selector onThread:key.thread withObject:notification waitUntilDone:NO];
        else if(key.runOnMainthread != nil && [key.runOnMainthread boolValue] == YES) {
            if(key.runAsync != nil && [key.runAsync boolValue] == YES) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [key.observer performSelector:selector withObject:notification];
                });
            } else {
                [key.observer performSelector:selector withObject:notification];
            }
        } else if(key.runAsync != nil && [key.runAsync boolValue] == YES) {
            [key.observer performSelectorInBackground:selector withObject:notification];
        } else {
            [key.observer performSelector:selector withObject:notification];
        }
    }
#pragma clang pop
}

@end

@interface NSMutableDictionary (NJSNotificationCenter)
- (NSArray*) valuesForKey:(NJSNotificationKey*) key;
@end

@implementation NSMutableDictionary (NJSNotificationCenter)

- (NSArray*) keysForKey:(NJSNotificationKey*) inKey {
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
    for(NJSNotificationKey *key in self.allKeys) {
        if([key class] != [NJSNotificationKey class]) continue; // Only operate on keys of type NJSNotificationKey
        if(inKey.observer != nil && inKey.observer != key.observer) continue;
        if(inKey.object != nil && inKey.object != key.object) continue;
        if(inKey.name != nil && ![inKey.name isEqualToString:key.name]) continue;
        
        [returnArray addObject:key];
    }
    
    return returnArray;
}


- (NSArray*) valuesForKey:(NJSNotificationKey*) inKey {
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
    NSArray *keys = [self keysForKey:inKey];
    for(NJSNotificationKey *key in keys) {
        NJSNotificationValue *val = [self objectForKey:key];
        NSAssert(val, @"Value should not be nil!");
        [returnArray addObject:val];
    }
    
    return returnArray;
}

@end

#pragma mark - NSNotificationCenter interface

@implementation NJSNotificationCenter {
    NSMutableDictionary *_observers;
}


static NJSNotificationCenter* notificationCenter = nil;
+ (instancetype)defaultCenter {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(notificationCenter != nil)
            return;

        notificationCenter = [[NJSNotificationCenter alloc] init];
        
    });
    return notificationCenter;
}

- (instancetype)init {
    if(notificationCenter != nil)
        return notificationCenter;
    
	self = [super init];
    if(self) {
        notificationCenter = self;
        
        _observers = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void) addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject {
    [self addObserver:observer selector:aSelector name:aName object:anObject priority:0];
}

- (void) postNotification:(NSNotification *)notification {
    NJSNotificationKey *key = [[NJSNotificationKey alloc] initWithObserver:nil name:notification.name object:notification.object];
    NSArray *keys;
    @synchronized(_observers) {
        keys = [[_observers keysForKey:key] sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES] ]];
    }
    
    for(NJSNotificationKey *fullKey in keys) {
        NSArray *singleValue;
        @synchronized(_observers) {
            singleValue = [_observers valuesForKey:fullKey];
        }
        NSAssert(singleValue.count == 1, @"Is single value");
        [singleValue[0] performForKey:fullKey notification:notification];
    }
}

- (void) postNotificationName:(NSString *)aName object:(id)anObject {
    NSNotification *notification = [NSNotification notificationWithName:aName object:anObject];
    [self postNotification:notification];
}

- (void) postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo {
    NSNotification *notification = [NSNotification notificationWithName:aName object:anObject userInfo:aUserInfo];
    [self postNotification:notification];
    
}

- (void) removeObserver:(id)observer {
    [self removeObserver:observer name:nil object:nil];
}

- (void) removeObserver:(id)observer name:(NSString *)aName object:(id)anObject {
    NJSNotificationKey *inKey = [[NJSNotificationKey alloc] initWithObserver:observer name:nil object:nil];
    NSArray *keys;
    @synchronized(_observers) {
        keys = [_observers keysForKey:inKey];
        for(NJSNotificationKey *key in keys) {
            [_observers removeObjectForKey:key];
        }
    }
    
}

- (id) addObserverForName:(NSString *)name object:(id)obj queue:(NSOperationQueue *)queue usingBlock:(void (^)(NSNotification *note))block {
    NSAssert(false, @"Not implemented yet. Imlpementations welcome, so do send a patch");
    return nil;
}

#pragma mark - NJSNotificationCenter extra interface

- (void) addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject priority:(NSInteger)priority {
    NJSNotificationKey *key = [[NJSNotificationKey alloc] initWithObserver:observer name:aName object:anObject];
    key.priority = priority;
    NJSNotificationValue *value = [[NJSNotificationValue alloc] initWithSelector:aSelector];
    NSAssert(value, @"Value cannot be nil!");
    @synchronized(_observers) {
        _observers[key] = value;
    }
}

- (void) addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject async:(BOOL)async {
    [self addObserver:observer selector:aSelector name:aName object:anObject async:async priority:0];
}

- (void) addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject async:(BOOL)async priority:(NSInteger) priority {
    NJSNotificationKey *key = [[NJSNotificationKey alloc] initWithObserver:observer name:aName object:anObject];
    key.priority = priority;
    key.runAsync = @(async);
    NJSNotificationValue *value = [[NJSNotificationValue alloc] initWithSelector:aSelector];
    @synchronized(_observers) {
        _observers[key] = value;
    }
}

- (void) addObserver:(id)observer block:(void (^)(NSNotification*))block name:(NSString *)aName object:(id)anObject async:(BOOL)async {
    [self addObserver:observer block:block name:aName object:anObject async:async priority:0];
}

- (void) addObserver:(id)observer block:(void (^)(NSNotification*))block name:(NSString *)aName object:(id)anObject async:(BOOL)async priority:(NSInteger) priority {
    NJSNotificationKey *key = [[NJSNotificationKey alloc] initWithObserver:observer name:aName object:anObject];
    key.priority = priority;
    key.runAsync = @(async);
    NJSNotificationValue *value = [[NJSNotificationValue alloc] initWithBlock:block];
    @synchronized(_observers) {
        _observers[key] = value;
    }
}

- (void) addObserverToMainThread:(id)observer block:(void (^)(NSNotification*))block name:(NSString *)aName object:(id)anObject async:(BOOL)async {
    [self addObserverToMainThread:observer block:block name:aName object:anObject async:async priority:0];
}

- (void) addObserverToMainThread:(id)observer block:(void (^)(NSNotification*))block name:(NSString *)aName object:(id)anObject async:(BOOL)async priority:(NSInteger) priority {
    NJSNotificationKey *key = [[NJSNotificationKey alloc] initWithObserver:observer name:aName object:anObject];
    key.priority = priority;
    key.runAsync = @(async);
    key.runOnMainthread = @YES;
    NJSNotificationValue *value = [[NJSNotificationValue alloc] initWithBlock:block];
    @synchronized(_observers) {
        _observers[key] = value;
    }
}

- (void) addObserverToMainThread:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject async:(BOOL)async {
    [self addObserverToMainThread:observer selector:aSelector name:aName object:anObject async:async priority:0];
}

- (void) addObserverToMainThread:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject async:(BOOL)async priority:(NSInteger) priority {
    NJSNotificationKey *key = [[NJSNotificationKey alloc] initWithObserver:observer name:aName object:anObject];
    key.priority = priority;
    key.runAsync = @(async);
    key.runOnMainthread = @YES;
    NJSNotificationValue *value = [[NJSNotificationValue alloc] initWithSelector:aSelector];
    @synchronized(_observers) {
        _observers[key] = value;
    }
}

- (void) addObserver:(id)observer toThread:(NSThread*)thread selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject async:(BOOL)async {
    [self addObserver:observer toThread:thread selector:aSelector name:aName object:anObject async:async priority:0];
}

- (void) addObserver:(id)observer toThread:(NSThread*)thread selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject async:(BOOL)async priority:(NSInteger) priority {
    NJSNotificationKey *key = [[NJSNotificationKey alloc] initWithObserver:observer name:aName object:anObject];
    key.priority = priority;
    key.runAsync = @(async);
    key.thread = thread;
    NJSNotificationValue *value = [[NJSNotificationValue alloc] initWithSelector:aSelector];
    @synchronized(_observers) {
        _observers[key] = value;
    }
}

- (void) addObserver:(id)observer toThread:(NSThread*)thread block:(void (^)(NSNotification*))block name:(NSString *)aName object:(id)anObject async:(BOOL)async {
    [self addObserver:observer toThread:thread block:block name:aName object:anObject async:async priority:0];
}

- (void) addObserver:(id)observer toThread:(NSThread*)thread block:(void (^)(NSNotification*))block name:(NSString *)aName object:(id)anObject async:(BOOL)async priority:(NSInteger) priority {
    NJSNotificationKey *key = [[NJSNotificationKey alloc] initWithObserver:observer name:aName object:anObject];
    key.priority = priority;
    key.runAsync = @(async);
    key.thread = thread;
    NJSNotificationValue *value = [[NJSNotificationValue alloc] initWithBlock:block];
    @synchronized(_observers) {
            _observers[key] = value;
    }
}

- (void) postNotification:(NSNotification *)notification async:(BOOL)async {
    if(async == NO)
        [self postNotification:notification];
    else
        [self performSelector:@selector(postNotification:) withObject:notification afterDelay:0.01f];
}

- (void) postNotificationName:(NSString *)aName object:(id)anObject async:(BOOL)async {
    [self postNotificationName:aName object:anObject userInfo:nil async:async];
}

- (void) postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo async:(BOOL)async {
    NSNotification *notification = [NSNotification notificationWithName:aName object:anObject userInfo:aUserInfo];
    [self postNotification:notification async:async];
}

- (NSArray*) listObservers {
    NSMutableArray *list;
    @synchronized(_observers) {
        list = [[NSMutableArray alloc] initWithCapacity:_observers.count];
        for(NJSNotificationKey *key in _observers.allKeys) {
            [list addObject:[NSString stringWithFormat:@"Observer: %p\tNotification: %@\tObject:%p", key.observer, key.name, key.object]];
        }
    }
    return list;
}

@end
