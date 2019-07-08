[![Swift 5](https://img.shields.io/badge/swift-5-lightgrey.svg?style=for-the-badge)](https://swift.org)
![iOS 8+](https://img.shields.io/badge/iOS-8-lightgrey.svg?style=for-the-badge)
[![Carthage](https://img.shields.io/badge/carthage-compatible-green.svg?style=for-the-badge)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/badge/cocoapods-compatible-green.svg?style=for-the-badge)](https://cocoapods.org/pods/PiuPiu)
[![GitHub](https://img.shields.io/github/license/mashape/apistatus.svg?style=for-the-badge)](https://github.com/cuba/PiuPiu/blob/master/LICENSE)
[![Build](https://img.shields.io/travis/cuba/PiuPiu/master.svg?style=for-the-badge)](https://travis-ci.org/cuba/PiuPiu)

PiuPiu
============

Formerly known as [NetworkKit](https://github.com/cuba/NetworkKit), the project was renamed to support CocoaPods.
PiuPiu adds the concept of `Futures` (aka: `Promises`) to iOS. It is intended to make netwoking calls cleaner and simpler and provides the developer with more customizability then any other networking framework.

**Q**: Why should I use this framework?
**A**: Because, you like clean code.

**Q**: Why the stupid name?
**A**: Because "piu piu" is the sound of lazers. And lazers are from the future.

**Q**: What sort of bear is best?
**A**: False! A black bear!

- [Updates](#updates)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Future](#future)
- [Encoding](#encoding)
- [Decoding](#decoding)
- [Memory Managment](#memory-managment)
- [Custom Encoding](#custom-encoding)
- [Custom Decoding](#custom-decoding)
- [Mock Dispatcher](#mock-dispatcher)
- [Dependencies](#dependencies)
- [Credits](#credits)
- [License](#license)

## Updates

### 1.3.0
* Rename `PewPew` to `PiuPiu`
  * To handle this migration, replace all `import PewPew` with `import PiuPiu`
* Fix build for Carthage
* Delete unnecessary files

### 1.2.0
* Make `ServerProvider` return an optional URL.  This will safely handle invalid URLs instead of forcing the developer to use a !.
* Add JSON array serialization method to BasicRequest

### 1.1.0
Removed default translations.  

You can add back this behaviour by extending `ResponseError`, `RequestError` and `SerializationError` and conforming to `LocalizedError` and (optionally) `CustomNSError`

To have the previous behaviour exactly as it was before (in `NetworkKit`), you can add the files found [here](https://github.com/cuba/PiuPiu/tree/11016136d299315fa16d9dc71757839981a5baff/Example/Example/Errors) and the localizations [here](https://github.com/cuba/PiuPiu/blob/11016136d299315fa16d9dc71757839981a5baff/Example/Example/Localizable.strings) to your project.

### 1.0.1 
Fixed crash when translating caused by renaming the project.

## Features

- [x] A wrapper around network requests
- [x] Uses `Futures` (ie. `Promises`) to allow scalablity and dryness
- [x] Convenience methods for deserializing Decodable and JSON 
- [x] Easy integration
- [x] Handles common http errors
- [x] Strongly typed and safely unwrapped responses
- [x] Easily extensible. Can easily work with frameworks such as `Alamofire`, `ObjectMapper` and `MapCodableKit`
- [x] Clean!

## Why Futures?
Most of us are used to using callbacks or delegates for our networking calls. And that's fine for simple applications. But as your applicaiton grows, you will quickly realize a few drawbacks to this simple approach.  Here are a few reasons why futures are the way to go:

1. They are extensible: Futures are objects and because they are objects, they are extensible. Traditionally you would add helper methods on delegates and callbacks or convenience methods on callbacks. Helper methods, although useful, feel a little bit dislocated. Helper methods on the other hand tend to be too specific and speghettify your code. Methods on the object itself, make it easier to debug, develop, name and document because they are context sensitive. And this will help write code, understand code and debug issues.  Plus, It's also nice to just press a `.` on your keyboard and see what methods you get instead of remembering the name of that helper class that handles the specific response object your receieved.
2. Asyncronous Do/Catch: There's an easier way to handle response and request errors. Anything you throw in the future's callbacks will be handled. This is normally tedious in delegates and callbacks as they always have to be wrapped around a do/catch block. Futures have a sort of do/catch mechanism for asyncronous tasks.
3. Multithreading: Futures offer better multithreading support because they have predefined and useful functions that work on seperate threads. So don't worry about parsing your data in the `then` callback. It won't lock your main thread.
4. One generic to rule them all: Futures use a generic result object. This means a future can be used for anything.  Network calls or heavy tasks: It doesn't matter.
5. Better compiler support: Forgot to call your callback? You don't have to worry about it with Futures because they are called for you as soon as you trigger `send()`  or `start()`. And if you forget to call `send()`, your compiler will remind you.
6. Pass them around: You can pass futures around and handle them where you need to.
7. Strongly typed: The object you recieve in the end is strongly typed so you don't need to cast or fail.  It will hande this for you.

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate PiuPiu into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "cuba/PiuPiu" ~> 1.3
```

Run `carthage update` to build the framework and drag the built `PiuPiu.framework` into your Xcode project.

## Usage

### 1. Import `PiuPiu` into your file

```swift
import PiuPiu
```

### 2. Implement a  `ServerProvider`

The server provider gives the server url.  The reason a simple URL is not used is so that you can dynamically change the url.  Say for example you have an environment picker.  You would have to recreate the dispatcher every time you change the environment.  The simplest way to create a ServerProvider is to just implement the protocol on your ViewController.

```swift
extension ViewController: ServerProvider {
    var baseURL: URL? {
        return URL(string: "https://example.com")!
    }
}
```

But you may chose to use a seperate object to implement the server provider or create a singleton object so you can share it througout your application. Because the reference to the server provider on the `RequestDispatcher` is weak, you don't have to worry about any circular references.

### 3. Making a request.

Now that we have our `ServerProvider` established, we can start making api calls. 

```swift
let dispatcher = RequestDispatcher(serverProvider: self)
let request = BasicRequest(method: .get, path: "/posts")

dispatcher.future(from: request).response({ response in
    // Handles all responses including negative responses such as 4xx and 5xx

    // The error object is available if we get an
    // undesirable status code such as a 4xx or 5xx
    if error = response.error {
        // Throwing an error in any callback will trigger the `error` callback.
        // This allows us to pool all failures in one place.
        throw error
    }

    let post = try response.decode(Post.self)
    // Do something with our deserialized object
    // ...
}).error({ error in
    // Handles any errors during the request process,
    // including anything thrown in any of the callback (except this one).
}).completion({
    // The completion callback is guaranteed to be called once
    // for every time the `start()` or `send()` method is triggered on the future.
    // 
}).start()
```

**NOTE**: Nothing will happen if you don't call `start()`.

### 4. Separating concerns and transforming the future

*Pun not indended (honestly)*

Now lets move the part of the future that decodes our object to another method.  This way, our business logic is not mixed up with our serialization logic.
One of the great thing about using futures is that we can return them!

Lets create a method similar to this:

```swift
private func getPosts() -> ResponseFuture<[Post]> {
    let dispatcher = RequestDispatcher(serverProvider: self)
    let request = BasicRequest(method: .get, path: "/posts")

    // We create a future and tell it to transform the response using the
    // `then` callback.
    return dispatcher.future(from: request).then({ response -> [Post] in
        // This callback transforms our response to another type
        // We can still handle errors the same way as we did before.
        
        if let error = response.error {
            // The error is available when a non-2xx response comes in
            // Such as a 4xx or 5xx
            // You may also parse a custom error object here.
            throw error
        }
        
        // Return the decoded object. If an error is thrown while decoding,
        // It will be caught in the `error` callback.
        return try response.decode([Post].self)
    })
}
```

**NOTE**: We intentionally did not call `start()` in this case. 

Then we can simply call it like this:

```swift
getPosts().response({ posts in
    // Handle the success which will give your posts.
    responseExpectation.fulfill()
}).error({ error in
    // Triggers whenever an error is thrown.
    // This includes deserialization errors, unwraping failures, and anything else that is thrown
    // in a any other throwable callback.
}).completion({
    // Always triggered at the very end to inform you this future has been satisfied.
}).send()
```

## Future

You've already seen that a `ResponseFuture` allows you to chain your callbacks, transform the response object and pass it around. But besides the simple examples above, there is so much more you can do to make your code amazingly clean!

```swift
dispatcher.future(from: request).then({ response -> Post in
    // Handles any responses and transforms them to another type
    // This includes negative responses such as 4xx and 5xx

    // The error object is available if we get an
    // undesirable status code such as a 4xx or 5xx
    if let error = response.error {
        // Throwing an error in any callback will trigger the `error` callback.
        // This allows us to pool all the errors in one place.
        throw error
    }
    
    return try response.decode(Post.self)
}).replace({ post -> ResponseFuture<EnrichedPost> in
    // Perform some operation that itself uses a future
    // such as something heavy like markdown parsing.
    // Any callback can be transformed to a future.
    return self.enrich(post: post)
}).join({ enrichedPost -> ResponseFuture<User> in
    // Joins a future with another one returning both results
    return self.fetchUser(forId: post.userId)
}).response({ enrichedPost, user in
    // The final response callback includes all the transformations and
    // Joins we had previously performed.
}).error({ error in
    // Handles any errors throw in any callbacks
}).completion({
    // At the end of all the callbacks, this is triggered once. Error or no error.
}).send()
```

### Callbacks

#### `response` callback

The `response` callback is triggered when the request is recieved and no errors are thrown in any chained callbacks (such as `then` or `join`).
At the end of the callback sequences, this gives you exactly what your transforms "promised" to return.

```swift
dispatcher.future(from: request).response({ response in
    // Triggered when a response is recieved and all callbacks succeed.
})
```

**NOTE**:  This method should **ONLY** be called **ONCE**.

#### `error` callback

Think of this as a `catch` on a `do` block. From the moment you trigger `send()`, the error callback is triggered whenever something is thrown during the callback sequence. This includes errors thrown in any other callback.

```swift
dispatcher.future(from: request).error({ error in
    // Any errors thrown in any other callback will be triggered here.
    // Think of this as the `catch` on a `do` block.
})
```

**NOTE**:  This method should **ONLY** be called **ONCE**.

#### `completion` callback

The completion callback is always triggered at the end after all `ResponseFuture` callbacks once every time `send()` or `start()` is triggered.

```swift
dispatcher.future(from: request).completion({
    // The completion callback guaranteed to be called once
    // for every time the `send` or `start` method is triggered on the callback.
})
```

**NOTE**:  This method should **ONLY** be called **ONCE**.

#### `then` callback

This callback transforms the `response` type to another type. This operation is done on a background queue so heavy operations won't lock your main queue. 

**WARNING**: You should avoid calling self in this callback . Use it solely for transforming the future.

```swift
dispatcher.future(from: request).then({ response -> Post in
    // The `then` callback transforms a successful response to another object
    // You can return any object here and this will be reflected on the `success` callback.
    return try response.decode(Post.self)
}).response({ post in
    // Handles any success responses.
    // In this case the object returned in the `then` method.
})
```

#### `replace` callback

This callback transforms the future to another type using another callback.  This allows us to make asyncronous calls inside our callbacks.

```swift
dispatcher.future(from: request).then({ response -> Post in
    return try response.decode(Post.self)
}).replace({ post -> ResponseFuture<EnrichedPost> in
    // Perform some operation operation that itself requires a future
    // such as something heavy like markdown parsing.
    return self.enrich(post: post)
}).response({ enrichedPost in
    // The final response callback has the enriched post.
})
```

#### `join` callback

This callback transforms the future to another type containing its original results plus the results of the returned callback. This allows us to make asyncronous calls in series.

```swift
dispatcher.future(from: request).then({ response -> Post in
    return try response.decode(Post.self)
}).join({ post -> ResponseFuture<User> in
    // Joins a future with another one returning both results
    return self.fetchUser(forId: post.userId)
}).response({ post, user in
    // The final response callback includes both results.
})
```

#### `send` or `start`

This will start the `ResponseFuture`. In other words, the `action` callback will be triggered and the requests will be sent to the server. 

**NOTE**: If this method is not called, nothing will happen (no request will be made).
**NOTE**: This method should **ONLY** be called **AFTER** declaring all of your callbacks (`success`, `failure`, `error`, `then` etc...)
**NOTE**:  This method should **ONLY** be called **ONCE**.

### Creating your own ResponseFuture

You can create your own ResponseFuture for a variety of reasons. If you do, you will have all the benefits you have seen so far.

Here is an example of a response future that does decoding in another thread.

```
return ResponseFuture<[Post]>(action: { future in
    // This is an example of how a future is executed and
    // fulfilled.
    DispatchQueue.global(qos: .userInitiated).async {
        // lets make an expensive operation on a background thread.
        // The below is just an example of how you can parse on a seperate thread.

        do {
            // Do an expensive operation here ....
            let posts = try response.decode([Post].self)

            DispatchQueue.main.async {
                // We should syncronyze the result back to the main thread.
                future.succeed(with: posts)
            }
        } catch {
            // We can handle any errors as well.
            DispatchQueue.main.async {
                // We should syncronize the error to the main thread.
                future.fail(with: error)
            }
        }
    }
})
```

**NOTE** You should **ALWAYS** syncronize the results on the main thread before succeeding or failing your future.

## Encoding

PiuPiu has some convenience methods for you to encode objects into JSON and add them to the `BasicRequest` object.

### Encode JSON `String`

```
var request = BasicRequest(method: .post, path: "/users")
request.setJSONBody(string: jsonString, encoding: .utf8)
```

### Encode JSON Object

```
let jsonObject: [String: Any?] = [
    "id": "123",
    "name": "Kevin Malone"
]

var request = BasicRequest(method: .post, path: "/users")
try request.setJSONBody(jsonObject: jsonObject)
```

### Encode `Encodable`

```
var request = BasicRequest(method: .post, path: "/posts")
try request.setJSONBody(encodable: myCodable)
```

### Custom Encoding (By setting the `Data` object)

```swift
var request = BasicRequest(method: .post, path: "/users")
request.httpBody = myData
```

### Wrap Encoding In a ResponseFuture

It might be beneficial to wrap the Request creation in a ResponseFuture. This will allow you to:
1. Delay the request creation at a later time when submitting the request.
2. Combine any errors thrown while creating the request in the error callback.

```swift
dispatcher.future(from: {
    var request = BasicRequest(method: .post, path: "/posts")
    try request.setJSONBody(myCodable)
    return request
}).error({ error in
    // Any error thrown while creating the request will trigger this callback.
}).send()
```

## Decoding

### Unwrapping `Data`

This will unwrap the data object for you or throw a ResponseError if it not there. This is convenent so that you don't have to deal with those pesky optionals. 

```swift
dispatcher.future(from: request).response({ response in
    let data = try response.unwrapData()

    // do something with data.
    print(data)
}).error({ error in 
    // Triggered when the data object is not there.
}).send()
```

### Decode `String`

```swift
dispatcher.future(from: request).response({ response in
    let string = try response.decodeString(encoding: .utf8)

    // do something with string.
    print(string)
}).error({ error in
    // Triggered when decoding fails.
}).send()
```

### Decode `Decodable`

```swift
dispatcher.future(from: request).response({ response in
    let posts = try response.decode([Post].self)

    // do something with the decodable object.
    print(posts)
}).error({ error in
    // Triggered when decoding fails.
}).send()
```

## Memory Managment

The `ResponseFuture` may have 3 types of strong references: 
1. The system may have a strong reference to the `ResponseFuture` after `send()` is called. This reference is temporary and will be dealocated once the system returns a response. This will never create a circular reference but as the future is held on by the system, it will not be released until **AFTER** a response is recieved or an error is triggered.
2. Any callback that references `self` has a strong reference to `self` unless `[weak self]` is explicitly specified.
3. The developer's own strong reference to the `ResponseFuture`.

### Strong callbacks

When **ONLY**  `1` and `2` applies to your case, a temporary circular reference is created until the future is resolved. You may wish to use `[weak self]` in this case but it is not necessary.

```swift
dispatcher.future(from: request).then({ response -> [Post] in
    // [weak self] not needed as `self` is not called
    return try response.decode([Post].self)
}).response({ posts in
    // [weak self] not needed but may be added. There is a temporary reference which will hold on to self while the request is being made.
    self.show(posts)
}).send()
```

**WARNING** If you use `[weak self]` do not forcefully unwrap `self` and never forcefully unwrap anything on `self` either. Thats just asking for crashes.

**!! DO NOT DO THIS. !!** Never do this. Not even if you're a programming genius. It's just asking for problems.

```swift
dispatcher.future(from: request).success({ response in
    // We are foce unwrapping a text field! DO NOT DO THIS!
    let textField = self.textField!

    // If we dealocated textField by the time the 
    // response comes back, a crash will occur
    textField.text = "Success"
}).send()
```

You will have crashes if you force unwrap anything in your callbacks (i.e. usign a `!`).  We suggest you **ALWAYS** avoid force unwrapping anything in your callbacks. 

Always unwrap your objects before using them. This includes any `IBOutlet`s that the system generates. Use a guard, Use an assert. Use anything but a `!`.


### Strong reference to a `ResponseFuture`

You may be holding a reference to your `ResponseFuture`. This is fine as long as you make the callbacks weak in order to avoid circular references. 

```swift
self.postResponseFuture = dispatcher.future(from: request).then({ response in
    // [weak self] not needed as `self` is not called
    let posts = try response.decode([Post].self)
    return SuccessResponse<[Post]>(data: posts, response: response)
}).response({ [weak self] response in
    // [weak self] needed as `self` is called
    self?.show(response.data)
}).completion({ [weak self] in
    // [weak self] needed as `self` is called
    self?.postResponseFuture = nil
})

// Perform other logic, add delay, do whatever you would do that forced you
// to store a reference to this ResponseFuture in the first place

self.postResponseFuture?.send()
```

**WARNING** If you hold strongly to your future but don't make `self` weak using `[weak self]` you are guaranteed to have a cirucular reference. The following is a bad example that should not be followed:

**!! DO NOT DO THIS !!**

```swift
self.strongResponseFuture = dispatcher.future(from: request).response({ response in
    // Both the `ResponseFuture` and `self` are held on by each other.
    // `self` will never be dealocated and neither will the future!
    self.show(response.data)
}).send()
```

if `self` has a strong reference to your `ResponseFuture` and the `ResponseFuture` has a strong reference to `self` through any callback, you have created a circular reference. Neither will be dealocated.

### Weak reference to a `ResponseFuture`

You may chose to have a weak reference to your ResponseFuture. This is fine, as long as you do it after calling `send()` as your object will be dealocated before you get a chance to do this.

```swift
self.weakResponseFuture = dispatcher.future(from: request).completion({
    // Always triggered
}).send()

// This ResponseFuture may or may not be nil at this point.
// This depends on if the system is holding on to the
// ResponseFuture as it is awaiting a response.
// but the callbacks will always be triggered. 
```

**NOTE** The following is an example of where we our request will never happen because we lose the referrence to the ResponseFuture before `send()` is triggered:

**DO NOT DO THIS**:

```swift
self.weakResponseFuture = dispatcher.future(from: request).completion({
    // [weak self]
    expectation.fulfill()
})

// WHOOPS!!!!
// Our object is already nil because we have not established a strong reference to it.
// The `send()` method will do nothing and no callback will be triggered.

self.weakResponseFuture?.send()
```

## Custom Encoding

You can extend BasicRequest to add encoding for any type of object.  

### ObjectMapper

`ObjectMapper` is not included in the framework. This is in order to make the framework much lighter for those that don't want to use it.  But if you want, you can easily add encoding support for `ObjectMapper`.  Here is an example how you can add `BaseMappable` (`Mappable` and `ImmutableMappable`) encoding support for objects and arrays:

```swift
extension BasicRequest {
    /// Add JSON body to the request from a `BaseMappable` object.
    ///
    /// - Parameters:
    ///   - mappable: The `BaseMappable` object to serialize into JSON.
    ///   - context: The context of the mapping object
    ///   - shouldIncludeNilValues: Wether or not we should serialize nil values into the json object
    mutating func setJSONBody<T: BaseMappable>(mappable: T, context: MapContext? = nil, shouldIncludeNilValues: Bool = false) {
        let mapper = Mapper<T>(context: context, shouldIncludeNilValues: shouldIncludeNilValues)

        guard let jsonString = mapper.toJSONString(mappable) else {
            return
        }

        self.setJSONBody(string: jsonString)
    }

    /// Add JSON body to the request from a `BaseMappable` array.
    ///
    /// - Parameters:
    ///   - mappable: The `BaseMappable` array to serialize into JSON.
    ///   - context: The context of the mapping object
    ///   - shouldIncludeNilValues: Wether or not we should serialize nil values into the json object
    mutating func setJSONBody<T: BaseMappable>(mappable: [T], context: MapContext? = nil, shouldIncludeNilValues: Bool = false) {
        let mapper = Mapper<T>(context: context, shouldIncludeNilValues: shouldIncludeNilValues)

        guard let jsonString = mapper.toJSONString(mappable) else {
            return
        }

        self.setJSONBody(string: jsonString)
    }
}
```

### MapCodableKit

[MapCodableKit](https://github.com/cuba/MapCodableKit) is a lightweight json parsing framework.

Similarly `MapCodableKit` support is no longer available on this framework.  But like `ObjectMapper` You can easily add back support for  `MapEncodable`. 

```swift
extension BasicRequest {
    /// Add body to the request from a `MapEncodable` object.
    ///
    /// - Parameters:
    ///   - mapEncodable: The `MapEncodable` object to serialize into JSON.
    ///   - options: Writing options for serializing the `MapEncodable` object.
    /// - Throws: Any serialization errors thrown by `MapCodableKit`.
    mutating public func setJSONBody<T: MapEncodable>(mapEncodable: T, options: JSONSerialization.WritingOptions = []) throws {
        ensureJSONContentType()
        self.httpBody = try mapEncodable.jsonData(options: options)
    }
}
```

## Custom Decoding

Similar to encoding, you can also add Decoding support for whatever decoder you are using, including `ObjectMapper` by extending the `ResponseInterface`

### ObjectMapper

```swift
extension ResponseInterface where T == Data? {

    /// Attempt to Decode the response data into an BaseMappable object.
    ///
    /// - Parameters:
    ///   - type: The mappable type to decode
    ///   - context: The Base mappable object
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
    func decodeMappable<D: BaseMappable>(_ type: D.Type, context: MapContext? = nil) throws  -> D {
        let jsonString = try self.decodeString()
        let mapper = Mapper<D>(context: context)

        guard let result = mapper.map(JSONString: jsonString) else {
            throw SerializationError.failedToDecodeResponseData(cause: nil)
        }

        return result
    }

    /// Attempt to decode the response data into a BaseMappable array.
    ///
    /// - Parameters:
    ///   - type: The array type to decode
    ///   - context: The Base mappable object
    /// - Returns: The decoded array
    /// - Throws: `SerializationError`
    func decodeMappable<D: BaseMappable>(_ type: [D].Type, context: MapContext? = nil) throws  -> [D] {
        let jsonString = try self.decodeString()
        let mapper = Mapper<D>(context: context)

        guard let result = mapper.mapArray(JSONString: jsonString) else {
            throw SerializationError.failedToDecodeResponseData(cause: nil)
        }

        return result
    }

    /// Attempt to decode the response data into a BaseMappable array.
    ///
    /// - Parameters:
    ///   - type: The dictionary type to decode
    ///   - context: The Base mappable object
    /// - Returns: The decoded array
    /// - Throws: `SerializationError`
    func decodeMappable<D: BaseMappable>(_ type: [String: D].Type, context: MapContext? = nil) throws  -> [String: D] {
        let jsonString = try self.decodeString()
        let mapper = Mapper<D>(context: context)

        guard let result = mapper.mapDictionary(JSONString: jsonString) else {
        throw SerializationError.failedToDecodeResponseData(cause: nil)
        }

        return result
    }

    /// Attempt to decode the response data into a BaseMappable array.
    ///
    /// - Parameters:
    ///   - type: The dictionary of arrays type to decode
    ///   - context: The Base mappable object
    /// - Returns: The decoded array
    /// - Throws: `SerializationError`
    func decodeMappable<D: BaseMappable>(_ type: [String: [D]].Type, context: MapContext? = nil) throws  -> [String: [D]] {
        let jsonObject = try self.decodeJSONObject()
        let mapper = Mapper<D>(context: context)

        guard let result = mapper.mapDictionaryOfArrays(JSONObject: jsonObject) else {
            throw SerializationError.failedToDecodeResponseData(cause: nil)
        }

        return result
    }
}
```

### MapCodableKit

[MapCodableKit](https://github.com/cuba/MapCodableKit) is a lightweight json parsing framework.

```swift
extension ResponseInterface where T == Data? {

    /// Attempt to deserialize the response data into a MapDecodable object.
    ///
    /// - Parameters:
    ///   - type: The map decodable type to decode
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
    func decodeMapDecodable<D: MapDecodable>(_ type: D.Type) throws -> D {
        let data = try self.unwrapData()

        do {
            // Attempt to deserialize the object.
            return try D(jsonData: data)
        } catch {
            // Wrap this error so that we're controlling the error type and return a safe message to the user.
            throw SerializationError.failedToDecodeResponseData(cause: error)
        }
    }

    /// Attempt to decode the response data into a MapDecodable array.
    ///
    /// - Parameters:
    ///   - type: The map decodable array type to decode
    /// - Returns: The map decodable array
    /// - Throws: `SerializationError`
    func decodeMapDecodable<D: MapDecodable>(_ type: [D].Type) throws  -> [D] {
        let data = try self.unwrapData()

        do {
            // Attempt to deserialize the object.
            return try D.parseArray(jsonData: data)
        } catch {
            // Wrap this error so that we're controlling the error type and return a safe message to the user.
            throw SerializationError.failedToDecodeResponseData(cause: error)
        }
    }
}
```

## Mock Dispatcher

Testing network calls is always a pain.  That's why we included the `MockURLRequestDispatcher`.  It allows you to simulate network responses without actually making network calls.

```swift
let url = URL(string: "https://jsonplaceholder.typicode.com")!
let dispatcher = MockURLRequestDispatcher(baseUrl: url, mockStatusCode: .ok)
let request = BasicRequest(method: .get, path: "/posts")
try dispatcher.setMockData(codable)

/// The url specified is not actually called.
dispatcher.future(from: request).send()
```

## Future Features

- [ ] Parallel calls
- [x] Sequential calls: 
- [ ] More futuresque request creation
- [ ] A more generic dispatcher. The response object is way too specific.
- [ ] Better multi-threading support

## Dependencies

PiuPiu includes...nothing. This is a light-weight library.

## Credits

PiuPiu is owned and maintained by Jacob Sikorski.

## License

PiuPiu is released under the MIT license. [See LICENSE](https://github.com/cuba/PiuPiu/blob/master/LICENSE) for details
