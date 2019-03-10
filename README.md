[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20watchos%20%7C%20tvos-lightgray.svg?style=flat)](https://dashboard.buddybuild.com/apps/592348f0b74ee700016fbbe6/build/latest?branch=master)

NetworkKit
============

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Encoding](#encoding)
- [Decoding](#decoding)
- [Promises](#promises)
- [MockDispatcher](#mockdispatcher)
- [Dependencies](#dependencies)
- [Credits](#credits)
- [License](#license)

## Features

- [x] A wrapper around network requests
- [x] Uses Promises to allow scalablity and dryness
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
let request = JSONRequest(method: .get, path: "/posts")

dispatcher.make(request).success({ response in
    // This method is triggered when a 2xx response comes in.

    let posts = try response.decode([Post].self)
    print(posts)
}).failure({ response in
    // This method is triggered whenever we get an error object when performing a data task.
    // All errors in the response object are ResponseError
    
    if let message = try? response.decodeString(encoding: .utf8) {
        print(message)
    }
}).error({ error in
    // Triggers whenever an error is thrown.
    // This includes deserialization errors, unwraping failures, and anything else that is thrown
    // in a `success`, `error`, `then` or `thenFailure` block in any chained promise.
    // These errors are often application related errors but can be caused
    // because of invalid server responses (example: when deserializing the response data).
    
    print(error)
}).send()
```

## Encoding
NetworkKit has convenience methods to encode objects into JSON using the `JSONRequest` object. `JSONRequest` simply adds the "Content-Type" type request an allows you to encode some basic data types into JSON, including:

### Data
You can manually create your data object if you wish.

```swift
var request = JSONRequest(method: .post, path: "/users")
request.httpBody = myData
```

### String
Since this is a JSON Request, this string should be encoded as JSON.

```
var request = JSONRequest(method: .post, path: "/users")
request.setHTTPBody(string: jsonString)
```

### Encode JSON Object

```
let jsonObject: [String: Any?] = [
    "id": "123",
    "name": "Kevin Malone"
]

var request = JSONRequest(method: .post, path: "/users")
try request.setHTTPBody(jsonObject: jsonObject)
```

### Encode JSON `String`

```
var request = JSONRequest(method: .post, path: "/users")
request.setHTTPBody(string: jsonString, encoding: .utf8)
```

### Encode `Encodable`

```
var request = JSONRequest(method: .post, path: "/posts")
try request.setHTTPBody(encodable: myCodable)
```

### Encode `MapEncodable`
MapCodableKit is a convenience frameworks that handles JSON serialization and deserialization. More information on this library can be found [here](https://github.com/cuba/MapCodableKit).

```
var request = JSONRequest(method: .post, path: "/posts")
try request.setHTTPBody(mapEncodable: myMapCodable)
```

### Wrap Encoding In a Promise

It might be beneficial to wrap the request creation in a promise. This will allow you to:
1. Delay the request creation at a later time when submitting the request.
2. Combine any errors thrown while creating the request in the error callback.

To quickly do this, there is a convenience method on the Dispatcher.

```swift
dispatcher.make(from: {
    var request = JSONRequest(method: .post, path: "")
    try request.setHTTPBody(myCodable)
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
dispatcher?.make(request).success({ response in
    let data = try response.unwrapData()

    // do something with data.
    print(data)
}).error({ error in 
    // Triggered when decoding fails.
}).send()
```

### Decode `String`

```swift
dispatcher.make(request).success({ response in
    let string = try response.decodeString(encoding: .utf8)

    // do something with string.
    print(string)
}).error({ error in
    // Triggered when decoding fails.
}).send()
```

### Decode `Decodable`

```swift
dispatcher.make(request).success({ response in
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
dispatcher.make(request).success({ response in
    let post = try response.decodeMapDecodable(Post.self)

    // do something with string.
    print(post)
}).error({ error in
    // Triggered when decoding fails.
}).send()
```

For arrays:

```swift
dispatcher.make(request).success({ response in
    let posts = try response.decodeMapDecodable([Post].self)

    // do something with string.
    print(posts)
}).error({ error in
    // Triggered when decoding fails.
}).send()
```

## Promises
Under the hood, NetworkKit uses a simple strongly typed implementation of a Promise.  This allows you to be as flexible as you want.

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
    // in a `make`, `success`, `error`, `then` or `thenFailure` block in any chained promise.
}).completion({
    // The completion callback guaranteed to be called once
    // for every time the `send` or `start` method is triggered on the callback.
}).send()
```

### Return a promise not the response.

Using promises instead of responses allow you to be more flexibly by adding additional behaviour.  Take, for example, this somewhat generic method that makes an api call to return a Post:

```swift
private func fetchPost(id: String) -> Promise<SuccessResponse<Data?>, ErrorResponse<Data?>> {
    let dispatcher = NetworkDispatcher(serverProvider: self)
    let request = JSONRequest(method: .get, path: "/posts/\(id)")

    return dispatcher.make(request)
}
```

It can then be handled in a more specific way:

```swift
fetchPost(id: 1).success({ response in
    // Show success
}).failure({ response in
    // Show error response
}).error({ error in
    // Show error
}).send()
```

### Memory Managment

The promise may have 3 types of strong references: 
1. The system may have a strong reference to the promise after `send` or `start` is called. This reference is temporary and will be dealocated once the system returns a response. This will never create a circular reference as it is held on by a system class which you cannot reference directly.
2. Any callback that references `self` has a strong reference to `self` unless `[weak self]` is explicitly specified.
3. The developer's own strong reference to the promise.

### Strong callbacks
When only  `1` and `2` applies to you, a memory leak is never created. But you need to be careful. Since the reference `1` holds on to the promise and the promise holds on to `self` (via the callback), `self` will not be dealocated until AFTER the response is returned and the callbacks are triggered.

```swift
dispatcher.make(request).then({ response -> SuccessResponse<[Post]> in
    // [weak self] not needed as `self` is not called
    let posts = try response.decode([Post].self)
    return SuccessResponse<[Post]>(data: posts, response: response)
}).success({ [weak self] response in
    // [weak self] needed as `self` is called
    self?.show(response.data)
}).send()
```

**DO NOT DO THIS**:
The following is an example of a circular reference:

```swift
self.strongPromise = dispatcher.make(request).success({ response in
    // Both the promise and self are held on by each other.
    // `self` will never be dealocated!
    self.show(response.data)
}).send()
```

**DO NOT DO THIS**:

You will have crashes if you are making calls to anything that is forced unwrapped (i.e. usign a `!`).  We suggest you make your callbacks weak or avoid force unwrapping anything unless absolutely sure it can succeed. Always avoid calling anything that uses `!` by always unwrapping it first.

```swift
self.strongPromise = dispatcher.make(request).success({ response in
    // We are foce unwrapping a text field. 
    let textField = self.textField!
    
    // If we dealocated textField by the time the 
    // response comes back, a crash will occur
    textField.text = "Success"
}).send()
```

### Storing your promise
You may be holding a reference to your promise. This is fine as long as you make either the promise or callbacks that reference `self` weak. 
This is an example of making the callbacks weak.

```swift
self.postPromise = dispatcher.make(request).then({ response in
    // [weak self] not needed as `self` is not called
    let posts = try response.decode([Post].self)
    return SuccessResponse<[Post]>(data: posts, response: response)
}).success({ [weak self] response in
    // [weak self] needed as `self` is called
    self?.show(response.data)
}).completion({ [weak self] in
    // [weak self] needed as `self` is called
    self?.postPromise = nil
})

// Perform other logic, add delay, do whatever you would do that forced you
// to store a reference to this promise in the first place

self.postPromise?.send()
```

You may chose to make the promise weak (or both the promise and the callbacks weak), This is fine, as long as you do it after calling `send` or `start` as your object will be dealocated before you get a chance to do this.

```swift
self.weakPromise = dispatcher.make(request).completion({
    // Always triggered
    expectation.fulfill()
}).send()

// This promise may or may not be nil at this point.
// This depends on if the system is holding on to the
// promise as it is awaiting a response.
// but the callbacks will always be triggered. 
```

**DO NOT DO THIS**:
The following is an example of where we our request will never happen because we lose the referrence to the promise before `send` is called:

```swift
self.weakPromise = dispatcher.make(request).completion({
    // [weak self]
    expectation.fulfill()
})

// OOPS!!!!
// Our object is already nil because we have not established a strong reference to it.
// The `send` method will do nothing. No callback will be triggered.

self.weakPromise?.send()
```

### Callbacks

#### `make` callback

The `make` callback creates the first promise which handles creating the initial success and failure responses.  This is the core of NetworkKit. 
There is also a convenice `make` method which accepts a `Request` object instead of a callback in case you don't need to handle any errors during the request creation process.

```swift
dispatcher.make(from: {
    var request = JSONRequest(method: .post, path: "/post")
    try request.setHTTPBody(newPost)
    return request
})
```

or 

```swift
let request = JSONRequest(method: .get, path: "/posts")
dispatcher.make(request)
```

Notice that the above examples uses the make method for the `GET` request and make callback for the `POST` request.  This is intentional as we often serialize some data during the creation of the `POST` request and this can result in failures. A `GET` request, on the other hand, rarely requires any serailization during the request cration process.  

#### `success` callback
The success callback when the request is successful and all chained promises (such as when performing decoding) are successful.  

At the end of the request callback sequences, this callback gives you exactly what your promise had promised you when a successful response occurs.

```swift
dispatcher.make(request).success({ response in
    // When everything succeeds including the network call and deserialization
})
```

#### `failure` callback
The failure callback is triggered when the there is a response but it is not valid. In a nutshell it gets triggered for all non-2xx responses such as a 401, 403, 404 or 500 error. This callback will give you the http response, status code and a ResponseError.

At the end of the request callback sequences, this callback gives you exactly what your promise had promised you when a failed response occurs.

```swift
dispatcher.make(request).failure({ response in
    // Triggered when network call fails gracefully.
})
```

#### `error` callback
The error callbak is triggered whenever something is thrown inside a response.  This includes errors thrown when attempting to deserialize the body for both successful and unsuccessful responses.

```swift
dispatcher.make(request).error({ error in
    // Any errors thrown in a `make`, `success`, `failure`, `then`, or `thenFailure`
    // callback will trigger the `error` callback.
})
```

#### `completion` callback
The completion callback is always triggered at the end after all promises have been fulfulled.

```swift
dispatcher.make(request).completion({
    // The completion callback guaranteed to be called once
    // for every time the `send` or `start` method is triggered on the callback.
})
```

#### `then` callback
This callback transforms the `success` type to another type.

```swift
dispatcher.make(request).then({ response -> Post in
    // The `then` callback transforms a successful response
    // You can return any object here and this will be reflected on the success callback.
    return try response.decode(Post.self)
}).success({ post in
    // Handles any success responses.
    // In this case the object returned in the `then` method.
})
```

#### `thenFailure` callback
This callback transforms the `error` type to another type.

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

#### `fullfill`
Fullfil a promise with the results of this promise. Both promises have to be identical.  In order to make them identical, first use `then` and `thenFailure` to transform the promise to the same type.

#### `start` or `send`
The two methods are identical. They will start the promise. In other words, the action callback will be triggered and the requests will be sent to the server. If this method is not called, nothing will happen (no request will be made). 

These methos should ALWAY be called AFTER declaring all of your callbacks (`success`, `failure`, `error`, `then` etc...)

## MockDispatcher

Testing network calls is always a pain.  That's why we included the `MockDispatcher`.  It allows you to simulate network responses without actually making network calls.

```swift
let url = URL(string: "https://jsonplaceholder.typicode.com")!
let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
let request = JSONRequest(method: .get, path: "/posts")
try dispatcher.setMockData(codable)

/// The url specified is not actually called.
dispatcher.make(request).send()
```

## Future Features

1. Parallel calls
2. Sequential calls
3. Custom localized strings returned on the error objects

## Dependencies

NetworkKit includes [MapCodableKit](https://github.com/cuba/MapCodableKit). This is a light-weight library.

## Credits

NetworkKit is owned and maintained by Jacob Sikorski.

## License

NetworkKit is released under the MIT license. [See LICENSE](https://github.com/cuba/NetworkKit/blob/master/LICENSE) for details
