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
github "cuba/NetworkKit" ~> 4.0
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
    // All errors in the response object are either ClientError, ServerError, or ResponseError
}).error({ [weak self] error in
    // Triggers whenever an error is thrown. In other words all errors that are created on the application side are here.
    // This includes decoding errors, unwrapped  
    // These errors are usually application related errors but (in terms of serialization) can be caused because of invalid server responses.
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

    requestPromise.fullfill(promise, success: { response in
        return response.data
    }, failure: { response in
        return response.data
    })
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

## MockDispatcher

Testing network calls is always a pain.  That's why there is an available `MockDispatcher`.  It allows you to simulate network responses without actually making network calls.

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
