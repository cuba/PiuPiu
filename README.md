[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20watchos%20%7C%20tvos-lightgray.svg?style=flat)](https://dashboard.buddybuild.com/apps/592348f0b74ee700016fbbe6/build/latest?branch=master)

NetworkKit
============

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Serialization](#serialization)
- [Deserializaiton](#deserialization)
- [Promises](#promises)
- [MockDispatcher](#mock-dispatcher)
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
github "cuba/NetworkKit" ~> 4.1
```

Run `carthage update` to build the framework and drag the built `NetworkKit.framework` into your Xcode project.

## Usage

### 1. Import `NetworkKit` into your file

```swift
import NetworkKit
```

### 2. Implement a  `ServerProvider`

The server provider is held on weakly by the NetworkDispatcher. Therefore it must be implemented on a class such as a ViewController or held strongly by some class.

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
let request = JSONRequest(method: .get, path: self.pathTextField.text ?? "")

dispatcher?.make(request).deserializeJSONString().success({ [weak self] response in
    // Triggered on a successful response and deserialization
    let jsonString = response.data
}).failure({ [weak self] response in
    // This method is triggered when a non 2xx response comes in.
    // All errors in the response object are ResponseError
}).error({ [weak self] error in
    // Triggers whenever an error is thrown. 
    // In other words, all errors that are created on the application fall through here.
    // This includes deserialization errors, unwraping failures, and anything else that is thrown 
    // in a `success`, `error`, `then` or `thenFailure` block in any chained promise.
    // These errors are oftern application related errors but can be caused 
    // because of invalid server responses (example: when deserializing the response data).
}).send()
```

## Serialization
NetworkKit can serialize objects into JSON.  Currently, this is done before the promise is created therefore it is not chained in the promise callbacks.

### `Data` 
You can manually create your data object if you wish

```swift
let requestObject = MockCodable()
var request = JSONRequest(method: .post, path: "/users")
request.httpBody = myData
```

### JSON `String`

```
var request = JSONRequest(method: .post, path: "/users")
request.setHTTPBody(jsonString: jsonString)
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

### `Encodable`

```
var request = JSONRequest(method: .post, path: "/posts")
try request.setHTTPBody(encodable: myCodable)
```

### `MapEncodable`

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

## Deserialization
NetworkKit can quickly deserialize any number of object types:

### `Data`

```swift
dispatcher?.make(request).deserializeData().success({ [weak self] response in
    let data = response.data
})
```

### JSON `String`

```swift
dispatcher?.make(request).deserializeJSONString().success({ [weak self] response in
    let data = response.data
})
```

### `Decodable`

```swift
dispatcher?.make(request).deserialize(to: MyCodable.self).success({ [weak self] response in
    let decodable = response.data
})
```

### `MapDecodable`
MapCodableKit is a convenience frameworks that handles JSON deserialization. More information on this library can be found [here](https://github.com/cuba/MapCodableKit).

For objects:

```swift
dispatcher?.send(request).deserializeMapDecodable().success({ [weak self] response in
    let decodable = response.data
}).failure({ [weak self] response in
    // This method is triggered when a response comes back but is unexpected.
}).error({ [weak self] error in
    // Triggers whenever an error is thrown, serialization failed or the request could not be created for whatever reason.
}).start()
```

For arrays:

```swift
dispatcher?.send(request).deserializeMapDecodableArray().success({ [weak self] response in
    let decodable = response.data
}).failure({ [weak self] response in
    // This method is triggered when a response comes back but is unexpected.
}).error({ [weak self] error in
    // Triggers whenever an error is thrown, serialization failed or the request could not be created for whatever reason.
}).start()
```

## Promises
Under the hood, NetworkKit uses a simple strongly typed implementation of a Promise.  This allows you to be as flexible as you want. We promise to give you better documentation on these promises soon :)

Here is an example of more advanced usage of promises from one of the tests:

```swift
Promise<MockCodable, MockDecodable>(action: { promise in
    try dispatcher.setMockData(codable)
    let requestPromise = dispatcher.make(request).deserialize(to: MockCodable.self).deserializeError(to: MockDecodable.self)

    // Convert the request promise so that it can fullfill this promise.
    requestPromise.then({ response -> MockCodable in
        // Converts the promise success object to `MapCodable`
        return response.data
    }).thenFailure({ response -> MockDecodable in
        // Converts the promise failure object to `MapCodable`
        return response.data
    }).fullfill(promise)
}).success({ response in
    XCTAssertEqual(response, codable)
    successExpectation.fulfill()
}).failure({ mockDecodable in
    XCTFail("Should not trigger the failure")
}).error({ error in
    XCTFail("Should not trigger the error")
}).completion({
    completionExpectation.fulfill()
}).start()
```

This promise utilizes all of the callbaks and features.

### `success` callback
The success callback when the request is successful and all chained promises (such as when performing deserialization) are successful.  You get at the end of the day exactly what your promise had promised you.

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

NetworkKit uses [MapCodableKit](https://github.com/cuba/MapCodableKit) for serialization.

## Credits

NetworkKit is owned and maintained by Jacob Sikorski.

## License

NetworkKit is released under the MIT license. [See LICENSE](https://github.com/cuba/NetworkKit/blob/master/LICENSE) for details
