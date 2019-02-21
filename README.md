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
    // This method is triggered when a non 2xx response comes in.
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

### JSON Object

```
let jsonObject: [String: Any?] = [
    "id": "123",
    "name": "Kevin Malone"
]

var request = JSONRequest(method: .post, path: "/users")
try request.setHTTPBody(jsonObject: jsonObject)
```

### Encodable

```
var request = JSONRequest(method: .post, path: "/posts")
try request.setHTTPBody(encodable: myCodable)
```

### MapEncodable
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

### Non-JSON Requests
You may create a custom request object by implementing the `Request` protocol.

## Decoding
NetworkKit can quickly decode any number of object types, including:

### `Data`

```swift
dispatcher?.make(request).success({ response in
    let data = try response.unwrapData()

    // do something with data.
    print(data)
}).error({ error in 
    // Triggered when decoding fails.
}).send()
```

###  `String`

```swift
dispatcher.make(request).success({ response in
    let string = try response.decodeString(encoding: .utf8)

    // do something with string.
    print(string)
}).error({ error in
    // Triggered when decoding fails.
}).send()
```

### `Decodable`

```swift
dispatcher.make(request).success({ response in
    let posts = try response.decode([Post].self)

    // do something with string.
    print(posts)
}).error({ error in
    // Triggered when decoding fails.
}).send()
```

### `MapDecodable`
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
Here is an example of more advanced usage of promises:

```swift
Promise<[Post], ServerError>(action: { promise in
    // `fullfill` calls the succeed and fail methods. The promise that is fullfilling another promise must be transformed first using `then` and `thenFailure` so that it is of the same type.
    // You may also succeed or fail the promise manually.
    // `fulfill `calls `start` so there is no need to call it.

    dispatcher.make(request).then({ response in
        // `then` callback is triggered only when a successful response comes back.
        return try response.decode([Post].self)
    }).thenFailure({ response in
        // `thenFailure` callback is only triggered when an unsusccessful response comes back.
        return try response.decode(ServerError.self)
    }).fullfill(promise)
}).success({ posts in
    // Then
    print(posts)
}).failure({ serverError in
    print(serverError)
}).error({ error in
    print(error)
}).completion({
    // Perform operation on completion
}).start()
```

This promise utilizes all of the callbaks and features.

### `success` callback
The success callback when the request is successful and all chained promises (such as when performing decoding) are successful.  You get at the end of the day exactly what your promise had promised you.

### `failure` callback
The failure callback is triggered when the there is a response but it is not valid. In a nutshell it gets triggered for all non-2xx responses such as a 401, 403, 404 or 500 error. This callback will give you the http response, status code and a ResponseError.

### `error` callback
The error callbak is triggered whenever something is thrown inside a response.  This includes errors thrown when attempting to deserialize the body for both successful and unsuccessful responses.

### `completion` callback
The completion callback is always triggered at the end after all promises have been fulfulled.

### `then` callback
This callback transforms the `success` type to another type.

### `thenFailure` callback
This callback transforms the `error` type to another type.

### `fullfill`
Fullfil a promise with the results of this promise. Both promises have to be identical.  In order to make them identical, first use `then` and `thenFailure` to transform the promise to the same type.

### `start` or `send`
The two methods are identical. They will start the promise. In other words, the action callback will be triggered and the requests will be sent to the server. If this method is not called, nothing will happen (no request will be made). 

These methos should ALWAY be called AFTER declaring all of your callbacks (`success`, `failure`, `error`, `then` etc...)

One useful sideffect is that you can create your request, store it and call `start()` later after some time.

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

## Dependencies

NetworkKit includes [MapCodableKit](https://github.com/cuba/MapCodableKit). This is a light-weight library.

## Credits

NetworkKit is owned and maintained by Jacob Sikorski.

## License

NetworkKit is released under the MIT license. [See LICENSE](https://github.com/cuba/NetworkKit/blob/master/LICENSE) for details
