## NJSNotificationCenter v1.0

### Author: Niklas Saers

### Description:

NSNotificationCenter is the hub of many event-driven applications. But sometimes reacting to events becomes tedious:
- Notifications are synchronous, but perhaps you expected them to be asynchronous
- Notifications get fired from a background thread, but you wanted to update the UI and expected the callback to be on the main thread
- Notifications don't guarantee what order they'll fire of the selectors in
- What's with selectors when we can use blocks?

I've had many of these qualms myself, and NJSNotificationCenter helps you relieve them. But beware! This is no replacement for a good architecture, and used incorrectly it might be a way to shoot yourself in your feet.

### Requirements

NJSNotificationCenter was written with iOS 7 in mind. No work has yet been done to support older iOS versions or OS X.

### To do:

- - (id) addObserverForName:(NSString *)name object:(id)obj queue:(NSOperationQueue *)queue usingBlock:(void (^)(NSNotification *note))block;
- More tests to make sure it replaces NSNotificationCenter completely
- Speed tests. I'm sure speed can be improved

### License

NJSNotificationCenter is under the two-clause BSD license attached in the file called LICENSE
