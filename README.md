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
- [x] Convenience methods for deserializing Decodable, MapDecodable (MapDecodableKit) and JSON 
- [x] Easy integration
- [x] Handles common http errors
- [x] Returns production safe error messages
- [x] Strongly typed and safely unwrapped responses

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

### 3. Send your request.


```swift
let dispatcher = NetworkDispatcher(serverProvider: self)
let request = BasicRequest(method: .get, path: "/posts")

dispatcher.future(from: request).then({ response -> Post in
    // Handles any responses and transforms them to another type
    // This includes negative responses such as 400s and 500s

    if error = response.error {
        // We throw the error so we can handle it in the `error` callback.
        // We can also handle the error response in a more custom way if we chose.
        throw error
    } else {
        return try response.decode(Post.self)
    }
}).response({ post in
    // Handles any success responses.
    // In this case the object returned in the `then` method.
}).error({ error in
    // Handles any errors during the request process,
    // including all request creation errors and anything
    // thrown in the `then` or `success` callbacks.
}).completion({
    // The completion callback guaranteed to be called once
    // for every time the `start` method is triggered on the callback.
}).start()
```

## Encoding
NetworkKit has convenience methods to encode objects into JSON using the `BasicRequest` object. `BasicRequest` simply adds the "Content-Type" type request an allows you to encode some basic data types into JSON, including:

### Data
You can manually create your data object if you wish.

```swift
var request = BasicRequest(method: .post, path: "/users")
request.httpBody = myData
```

### String
Since this is a JSON Request, this string should be encoded as JSON.

```
var request = BasicRequest(method: .post, path: "/users")
request.setJSONBody(string: jsonString)
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

### Encode JSON `String`

```
var request = BasicRequest(method: .post, path: "/users")
request.setJSONBody(string: jsonString, encoding: .utf8)
```

### Encode `Encodable`

```
var request = BasicRequest(method: .post, path: "/posts")
try request.setJSONBody(encodable: myCodable)
```

### Encode `MapEncodable`
MapCodableKit is a convenience frameworks that handles JSON serialization and deserialization. More information on this library can be found [here](https://github.com/cuba/MapCodableKit).

```
var request = BasicRequest(method: .post, path: "/posts")
try request.setJSONBody(mapEncodable: myMapCodable)
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

### Sending Non-JSON Requests
You may create a custom request object by implementing the `Request` protocol.

## Decoding
NetworkKit can quickly decode any number of object types, including:

### Unwrapping `Data`

```swift
dispatcher.future(from: request).success({ response in
    let data = try response.unwrapData()

    // do something with data.
    print(data)
}).error({ error in 
    // Triggered when decoding fails.
}).send()
```

### Decode `String`

```swift
dispatcher.future(from: request).success({ response in
    let string = try response.decodeString(encoding: .utf8)

    // do something with string.
    print(string)
}).error({ error in
    // Triggered when decoding fails.
}).send()
```

### Decode `Decodable`

```swift
dispatcher.future(from: request).success({ response in
    let posts = try response.decode([Post].self)

    // do something with string.
    print(posts)
}).error({ error in
    // Triggered when decoding fails.
}).send()
```

### Decode `MapDecodable`
MapCodableKit is a convenience frameworks that handles JSON serialization and deserialization. More information on this library can be found [here](https://github.com/cuba/MapCodableKit).

For objects:

```swift
dispatcher.future(from: request).success({ response in
    let post = try response.decodeMapDecodable(Post.self)

    // do something with string.
    print(post)
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

A `ResponseFuture` is similar to a `Promse` except that it is simpler in that it does not handle failures (ie it has no `failure` callback).  This allows you to simplify the response process by not having to handle failures and errors seperately as they are often handled the same way.

Here is an example of a request that returns a `ResponseFuture` instead of a `ResponseFuture`

```swift
dispatcher.future(from: request).then({ response -> Post in
    // Handles any responses and transforms them to another type
    // This includes positive resposes like 200s and
    // negative responses such as 400s and 500s

    if error = response.error {
        // We throw the error so we can handle it in the `error` callback.
        // If we want we can do some more custom parsing of the error object.
        // and throw a more custom error object.
        throw error
    } else {
        // if we have no error, we just return the decoded object
        // If anything is thrown, it will be caught in the `error` callback.
        return try response.decode(Post.self)
    }
}).response({ post in
    // Handles any success responses.
    // In this case the object returned in the `then` method.
}).error({ error in
    // Handles any errors during the request process,
    // including all request creation errors and anything
    // thrown in the `then` or `success` callbacks.
}).completion({
    // The completion callback guaranteed to be called once
    // for every time the `start` method is triggered on the callback.
}).send()
```

### Callbacks

#### `future` callback

The `future` callback creates the first `ResponseFuture`. This future will will send the request once the `send()` method is triggered.  The combination of callbacks you can create is endless.  You can transform, you can change your responses in any way as you go.  

```swift
return dispatcher.future(from: {
    var request = BasicRequest(method: .post, path: "/post")
    try request.setJSONBody(newPost)
    return request
})
```

There is also a convenice `future` method that accepts a `callback` instead of the request object so you can handle any errors during the request creation process. It also allows you to wrap the request creation process into a callback so that nothing is actually executed until after `send()` is triggered.

```swift
let request = BasicRequest(method: .get, path: "/posts")
return dispatcher.future(from: request)
```

Notice that the above examples uses the make method for the `GET` request and make callback for the `POST` request.  This is intentional as we often serialize some data during the creation of the `POST` request and this can result in failures. A `GET` request, on the other hand, rarely requires any serailization during the request cration process.

#### `response` callback

The success callback when the request is recieved and all chained `ResponseFuture` callbacks (such as then or success) don't thow any errors.  

At the end of the request callback sequences (including `then` callbacks), this gives you exactly what your expect to recieve in your `ResponseFuture`.

```swift
dispatcher.future(from: request).response({ response in
    // When a response is recieved
})
```

#### `error` callback

The error callbak is triggered whenever something is thrown when handling the request or response.  This includes errors thrown when attempting to deserialize the body for both successful and unsuccessful responses.

```swift
dispatcher.future(from: request).error({ error in
    // Any errors thrown in a `make`, `future`, `success`, `failure`, `then`, or `thenFailure`
    // callback will trigger this callback.
})
```

#### `completion` callback

The completion callback is always triggered at the end after all `ResponseFuture` callbacks once every time `send()` or `start()`  (`Promise` only) is triggered.

```swift
dispatcher.future(from: request).completion({
    // The completion callback guaranteed to be called once
    // for every time the `send` or `start` method is triggered on the callback.
})
```

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

#### `fulfill`

Fulfil a `ResponseFuture` (or a `Promise`) with the results of this `ResponseFuture` (or `Promise`). Both have to be identical (i.e. They have the same success and failure (`Promise`) objects).  In order to make them identical, first use `then` and `thenFailure` (`Promise` only) to transform them to the same type.

#### `send`

This will start the `ResponseFuture`. In other words, the `action` callback will be triggered and the requests will be sent to the server. If this method is not called, nothing will happen (no request will be made).

These methos should **ALWAY** be called **AFTER** declaring all of your callbacks (`success`, `failure`, `error`, `then` etc...)

## Promise

This works the same way as a `ResponseFuture` except that a `Promise` will treat the success and failure callbacks seperately. 

### Full Example

```swift
dispatcher.make(request).then({ response -> Post in
    // The `then` callback transforms a successful response
    return try response.decode(Post.self)
}).thenFailure({ response -> ServerErrorDetails in
    // The `thenFailure` callback transforms a failed response
    return try response.decode(ServerErrorDetails.self)
}).success({ post in
    // Handles any success responses.
    // In this case the object returned in the `then` method.
}).failure({ serverError in
    // Handles any graceful errors.
    // In this case the object returned in the `thenFailure` method.
}).error({ error in
    // Handles any ungraceful errors.
    // This includes deserialization errors, unwraping failures, and anything else that is thrown
    // in a `make`, `success`, `error`, `then` or `thenFailure` block in any chained ResponseFuture.
}).completion({
    // The completion callback guaranteed to be called once
    // for every time the `send` or `start` method is triggered on the callback.
}).send()
```

### Convert a `Promise` to a `ResponseFuture`

You can easily convert a `Promise` to a `ResponseFuture` with the following code:

```swift
dispatcher.make(request).future({ failedResponse in
    // Sice a `SimplePromse` does not handle `failure` callbacks,
    // we have to transform this to an `Error` object.
    // This is triggered when a failed response is recieved
    // But it always transforms the `FutreResponse` to a `Promse`.

    // You can simply return the response error or return something a little more custom
    // NOTE: You may want to use `dispatcher.future(from: request)` instead.
    return failedResponse.error
}).response({ response in
    // A success response. Because we used a ResponseFuture, this returns a `SuccessResponse`.
    // However we can have a bit more control, if we use `dispatcher.future(from: request)` directly.
}).error({ error in
    // This handles all errors thrown during the request creation process and
    // the error returned in the `promise` callback.
}).completion({
    // Always triggered once for every time we call `start()`
}).send()
```

### Callbacks

#### `success` callback

The success callback when the request is recieved and all chained `Promise` callbacks (such as then or success) don't thow any errors.  

At the end of the request callback sequences (including `then` callbacks), this callback gives you exactly what your expect to recieve in your `Promise`.

```swift
dispatcher.make(request).success({ response in
    // When everything succeeds including the network call and deserialization
    // Anything we throw here will be handled in the `error` callback.
})
```

#### `failure` callback

NOTE: `Promise` only.  This is only available when calling `dispatcher.make`.

The failure callback is triggered when the there is a response but it is not valid. In a nutshell it gets triggered for all non-2xx responses such as a 401, 403, 404 or 500 error. This callback will give you the http response, status code and a `ResponseError`.

At the end of the request callback sequences, this callback gives you exactly what your `Promise` had "failed" to promise omitting any errors.  Or you can see it as a callback promises to be triggered if the error object you expect is recieved..

```swift
dispatcher.future(from: request).failure({ response in
    // Triggered when network call fails gracefully.
})
```

#### `error` callback

The error callbak is triggered whenever something is thrown when handling the request or response.  This includes errors thrown when attempting to deserialize the body for both successful and unsuccessful responses.

```swift
dispatcher.future(from: request).error({ error in
    // Any errors thrown in a `make`, `future`, `success`, `failure`, `then`, or `thenFailure`
    // callback will trigger this callback.
})
```

#### `completion` callback

The completion callback is always triggered at the end after all `ResponseFuture` callbacks once every time `send()` or `start()`  (`Promise` only) is triggered.

```swift
dispatcher.future(from: request).completion({
    // The completion callback guaranteed to be called once
    // for every time the `send` or `start` method is triggered on the callback.
})
```

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

#### `thenFailure` callback

This callback transforms the `failure` type to another type.

```swift
dispatcher.make(request).thenFailure({ response -> ResponseError in
    // The `thenFailure` callback transforms a failed response.
    // You can return any object here and this will be reflected on the failure callback.
    return response.error
}).failure({ responseError in
    // Handles any failed responses.
    // In this case the object returned in the `thenFailure` method.
}).send()
```

#### `fulfill`

Fulfil a given `Promise` with the results of this  `Promise`. Both have to be identical (i.e. They have the same success and failure .  In order to make them identical, first use `then` and `thenFailure` to transform them to the same type.

#### `send`

This will start the `ResponseFuture`. In other words, the `action` callback will be triggered and the requests will be sent to the server. If this method is not called, nothing will happen (no request will be made).

These methos should **ALWAY** be called **AFTER** declaring all of your callbacks (`success`, `failure`, `error`, `then` etc...)

#### `start`

NOTE: `Promise` only.  This is only available when calling `response.make`.

Convience method for the `send` callback.

These methos should **ALWAY** be called **AFTER** declaring all of your callbacks (`success`, `failure`, `error`, `then` etc...)

As we can see, you have to add logic to convert the `failure` callback object to an `Error` object as no `failure` callback is available on a `ResponseFuture`. This is just a convinience method as you can simply use `dispatcher.future(from: request)`.

## Memory Managment

The `ResponseFuture` or a `Promise` may have 3 types of strong references: 
1. The system may have a strong reference to the `ResponseFuture` or a `Promise` after `send()` or `start()` is called. This reference is temporary and will be dealocated once the system returns a response. This will never create a circular reference but as the promise is held on by the system, it will not be released until after a response is recieved or an error is triggered.
2. Any callback that references `self` has a strong reference to `self` unless `[weak self]` is explicitly specified.
3. The developer's own strong reference to the `ResponseFuture`.

### Strong callbacks

When only  `1` and `2` applies to you, no circular reference is created. However the object reference as `self` is held on stongly temporarily until the request returns or an error is thrown.  You may wish to use `[weak self]` in this case but it is not necessary. 

```swift
dispatcher.future(from: request).then({ response -> SuccessResponse<[Post]> in
    // [weak self] not needed as `self` is not called
    let posts = try response.decode([Post].self)
    return SuccessResponse<[Post]>(data: posts, response: response)
}).response({ response in
    self.show(response.data)
}).send()
```

The following code is valid because we are not storing the future as a variable. But you need to be careful. Since the reference `1` (the system) holds on to the `ResponseFuture` and the `ResponseFuture` holds on to `self` (via the callback), `self` will not be dealocated until AFTER the response is returned and the callbacks are triggered. We have to make sure that we never force unwrap variables on self like the example below:

**DO NOT DO THIS**:

```swift
dispatcher.future(from: request).success({ response in
    // We are foce unwrapping a text field. 
    let textField = self.textField!

    // If we dealocated textField by the time the 
    // response comes back, a crash will occur
    textField.text = "Success"
}).send()
```

You will have crashes if you force unwrap anything in your callbacks (i.e. usign a `!`).  We suggest you ALWAYS avoid force unwrapping anything in your callbacks. Always unwrap your objects before using them including any `IBOutlet`s that the system generates. 

### Strong reference to a `ResponseFuture`

You may be holding a reference to your `ResponseFuture`. This is fine as long as you make the callbacks weak in order to avoid circular reference. 

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

If you hold strongly to your future but don't make `self` weak using `[weak self]` you are guaranteed to have a cirucular reference. The following is a bad example that should not be followed:

**DO NOT DO THIS**

```swift
self.strongResponseFuture = dispatcher.future(from: request).success({ response in
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

The following is an example of where we our request will never happen because we lose the referrence to the ResponseFuture before `send()` is triggered:

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

1. Parallel calls
2. Sequential calls
3. Custom localized strings returned on the error objects
4. Custom translations

## Dependencies

NetworkKit includes [MapCodableKit](https://github.com/cuba/MapCodableKit). This is a light-weight library.

## Credits

NetworkKit is owned and maintained by Jacob Sikorski.

## License

NetworkKit is released under the MIT license. [See LICENSE](https://github.com/cuba/NetworkKit/blob/master/LICENSE) for details
