[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20watchos%20%7C%20tvos-lightgray.svg?style=flat)](https://dashboard.buddybuild.com/apps/592348f0b74ee700016fbbe6/build/latest?branch=master)

NetworkKit
============

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Encoding](#encoding)
- [Decoding](#decoding)
- [ResponseFuture](#ResponseFuture)
- [MockDispatcher](#mockdispatcher)
- [Dependencies](#dependencies)
- [Credits](#credits)
- [License](#license)

## Features

- [x] A wrapper around network requests
- [x] Uses ResponseFuture to allow scalablity and dryness
- [x] Convenience methods for deserializing Decodable and JSON 
- [x] Easy integration
- [x] Handles common http errors
- [x] Returns production safe error messages
- [x] Strongly typed and safely unwrapped responses
- [x] Easily extensible to support other networking tools and frameworks such as Alamofire, ObjectMapper and MapCodableKit

## Installation

### Carthage

[Carthage](https://github.com/cuba/NetworkKit) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate NetworkKit into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "cuba/NetworkKit" ~> 4.2
```

Run `carthage update` to build the framework and drag the built `NetworkKit.framework` into your Xcode project.

## Usage

### 1. Import `NetworkKit` into your file

```swift
import NetworkKit
```

### 2. Implement a  `ServerProvider`

The server provider is held on weakly by the NetworkDispatcher. Therefore it must be implemented on a class such as a ViewController or another class that is held strongly.
The reason for this is so that you can dynamically return a url (ex: it changes based on an environment picker).

```swift
extension ViewController: ServerProvider {
    var baseURL: URL {
        return URL(string: "https://example.com")!
    }
}
```

### 3. Making a request.

Now that we have our ServerProvider established, we can start making api calls. 

```swift
let dispatcher = NetworkDispatcher(serverProvider: self)
let request = BasicRequest(method: .get, path: "/posts")

dispatcher.future(from: request).response({ response in
    // Handles any responses including negative responses such as 4xx and 5xx

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
    // including all request creation errors and anything
    // thrown in the `then` or `success` callbacks.
}).completion({
    // The completion callback is guaranteed to be called once
    // for every time the `start` method is triggered on the future.
}).start()
```

**NOTE**: Nothing will happen if you don't call `start()`.

### 4. Splitting up concerns and transforming the future

*Pun not indended (honestly)*

Now lets decode our object somewhere else.  This way, our business logic is not mixed up with our serialization logic. One of the great thing about futures is that we can return them! So now we can move the serialization part of our logic somewhere else.

If we have the following method

```swift
private func getPosts() -> ResponseFuture<[Post]> {
    let dispatcher = NetworkDispatcher(serverProvider: self)
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

Then we can simply do this:

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

## Encoding
NetworkKit has convenience methods to encode objects into JSON using the `BasicRequest` object. `BasicRequest` simply adds the "Content-Type" type request an allows you to encode some basic data types into JSON, including:

### Data
You can manually create your data object if you wish.

```swift
var request = BasicRequest(method: .post, path: "/users")
request.httpBody = myData
```

### Encode JSON `String`
Since this is a JSON Request, this string should be encoded as JSON.

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

### Wrap Encoding In a ResponseFuture

It might be beneficial to wrap the request creation in a ResponseFuture. This will allow you to:
1. Delay the request creation at a later time when submitting the request.
2. Combine any errors thrown while creating the request in the error callback.

To quickly do this, there is a convenience method on the Dispatcher.

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

NetworkKit can decode any number of object types.

### Unwrapping `Data`

```swift
dispatcher.future(from: request).response({ response in
    let data = try response.unwrapData()

    // do something with data.
    print(data)
}).error({ error in 
    // Triggered when decoding fails.
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

    // do something with string.
    print(posts)
}).error({ error in
    // Triggered when decoding fails.
}).send()
```

For arrays:

```swift
dispatcher.future(from: request).success({ response in
    let posts = try response.decodeMapDecodable([Post].self)

    // do something with string.
    print(posts)
}).error({ error in
    // Triggered when decoding fails.
}).send()
```

## ResponseFuture

You've already seen that a `ResponseFuture` allows you to chain your callbacks, transform the response object and pass it around.  But besides the simple example above, there is so much more you can do.

```swift
dispatcher.future(from: request).then({ response -> Post in
    // Handles any responses and transforms them to another type
    // This includes negative responses such as 4xx and 5xx

    // The error object is available if we get an
    // undesirable status code such as a 4xx or 5xx
    if let error = response.error {
        // Throwing an error in any callback will trigger the `error` callback.
        // This allows us to pool all our errors in one place.
        throw error
    }
    
    return try response.decode(Post.self)
}).replace({ post -> ResponseFuture<EnrichedPost> in
    // Perform some operation operation that itself requires a future
    // such as something heavy like markdown parsing.
    return self.enrich(post: post)
}).join({ enrichedPost -> ResponseFuture<User> in
    // Joins a future with another one
    return self.fetchUser(forId: post.userId)
}).response({ enrichedPost, user in
    // The final response callback includes all the transformations and
    // Joins we had previously performed.
}).error({ error in
    // Handles any errors throw in any callbacks
}).completion({
    // At the end of all the callbacks, this is triggered.
}).send()
```

### Callbacks

#### `response` callback

The success callback when the request is recieved and all chained `ResponseFuture` callbacks (such as then or success) don't thow any errors.  
At the end of the callback sequences, this gives you exactly what your transforms promised to return.

```swift
dispatcher.future(from: request).response({ response in
    // When a response is recieved
})
```

**NOTE**:  This method should **ONLY** be called **ONCE**.

#### `error` callback

The error callback is triggered whenever something is thrown during the callback sequence from the moment you trigger `send()`.  This includes errors thrown when attempting to deserialize the body for both successful and unsuccessful responses, errors in any `then`, `join`, `replace` and `response` callbacks.

```swift
dispatcher.future(from: request).error({ error in
    // Any errors thrown in any of the callbacks (except this one)
})
```

**NOTE**:  This method should **ONLY** be called **ONCE**.

#### `completion` callback

The completion callback is always triggered at the end after all `ResponseFuture` callbacks once every time `send()` or `start()`  (`Promise` only) is triggered.

```swift
dispatcher.future(from: request).completion({
    // The completion callback guaranteed to be called once
    // for every time the `send` or `start` method is triggered on the callback.
})
```

**NOTE**:  This method should **ONLY** be called **ONCE**.

#### `then` callback

This callback transforms the `success` type to another type.

```swift
dispatcher.future(from: request).then({ response -> Post in
    // The `then` callback transforms a successful response
    // You can return any object here and this will be reflected on the success callback.
    return try response.decode(Post.self)
}).response({ post in
    // Handles any success responses.
    // In this case the object returned in the `then` method.
})
```

#### `send` or `start`

This will start the `ResponseFuture`. In other words, the `action` callback will be triggered and the requests will be sent to the server. 

**NOTE**: If this method is not called, nothing will happen (no request will be made).
**NOTE**: This method should **ALWAYS** be called **AFTER** declaring all of your callbacks (`success`, `failure`, `error`, `then` etc...)
**NOTE**:  This method should **ONLY** be called **ONCE**.

### Creating your own ResponseFuture

You can create your own ResponseFuture for a variety of reasons. If you do, you will have all the benefits you have seen so far.

Here is an example of a response future that does decoding in another thread.

```
return ResponseFuture<[Post]>(action: { future in
    // This is an example of how a future is executed and
    // fulfilled.

    // You should always syncronize
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

**NOTE** You should **ALWAYS** syncronize the results on the main thread before succeeding or failing your future

## Memory Managment

The `ResponseFuture` may have 3 types of strong references: 
1. The system may have a strong reference to the `ResponseFuture` after `send()` is called. This reference is temporary and will be dealocated once the system returns a response. This will never create a circular reference but as the promise is held on by the system, it will not be released until **AFTER** a response is recieved or an error is triggered.
2. Any callback that references `self` has a strong reference to `self` unless `[weak self]` is explicitly specified.
3. The developer's own strong reference to the `ResponseFuture`.

### Strong callbacks

When **ONLY**  `1` and `2` applies to you, no circular reference is created. However the object reference as `self` is held on stongly temporarily until the request returns or an error is thrown.  You may wish to use `[weak self]` in this case but it is not necessary.

```swift
dispatcher.future(from: request).then({ response -> [Post] in
    // [weak self] not needed as `self` is not called
    return try response.decode([Post].self)
}).response({ posts in
    self.show(posts)
}).send()
```

**WARNING** If you use `[weak self]` do not forcefully unwrap `self` and never forcefully unwrap anything on `self`.

**!! DO NOT DO THIS !!**:

```swift
dispatcher.future(from: request).success({ response in
    // We are foce unwrapping a text field! DON NOT DO THIS!
    let textField = self.textField!

    // If we dealocated textField by the time the 
    // response comes back, a crash will occur
    textField.text = "Success"
}).send()
```

You will have crashes if you force unwrap anything in your callbacks (i.e. usign a `!`).  We suggest you **ALWAYS** avoid force unwrapping anything in your callbacks. Always unwrap your objects before using them including any `IBOutlet`s that the system generates. 

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

## Custom Decoder

Similar to encoding, you can also add Decoding support for whatever decoder you are using, including `ObjectMapper` by extending the `ResponseInterface`

### ObjectMapper

```swift
extension ResponseInterface where T == Data? {
    /// Attempt to Decode the response data into an BaseMappable object.
    ///
    /// - Returns: The decoded object
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
    /// - Returns: The decoded array
    func decodeMappable<D: BaseMappable>(_ type: [D].Type, context: MapContext? = nil) throws  -> [D] {
        let jsonString = try self.decodeString()
        let mapper = Mapper<D>(context: context)

        guard let result = mapper.mapArray(JSONString: jsonString) else {
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
    /// - Returns: The decoded object
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
    /// - Returns: The decoded array
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

## MockDispatcher

Testing network calls is always a pain.  That's why we included the `MockDispatcher`.  It allows you to simulate network responses without actually making network calls.

```swift
let url = URL(string: "https://jsonplaceholder.typicode.com")!
let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
let request = BasicRequest(method: .get, path: "/posts")
try dispatcher.setMockData(codable)

/// The url specified is not actually called.
dispatcher.future(from: request).send()
```

## Future Features

[  ] Parallel calls
[x] Sequential calls: 
[  ] Custom translations
[  ] More futuresque request creation
[  ] A more generic dispatcher. The response object is way too specific.

## Dependencies

NetworkKit includes. This is a light-weight library.

## Credits

NetworkKit is owned and maintained by Jacob Sikorski.

## License

NetworkKit is released under the MIT license. [See LICENSE](https://github.com/cuba/NetworkKit/blob/master/LICENSE) for details
