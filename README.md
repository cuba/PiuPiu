[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20watchos%20%7C%20tvos-lightgray.svg?style=flat)](https://dashboard.buddybuild.com/apps/592348f0b74ee700016fbbe6/build/latest?branch=master)

NetworkKit
============

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
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

dispatcher?.send(request).deserializeJSONString().success({ [weak self] response in
    let jsonString = response.data
}).failure({ [weak self] response in
    // This method is triggered when a response comes back but is unexpected.
}).error({ [weak self] error in
    // Triggers whenever an error is thrown, serialization failed or the request could not be created for whatever reason.
}).start()
```

## Deserialization
NetworkKit can quickly deserialize any number of object types:

### `Data`

```swift
dispatcher?.send(request).deserializeData().success({ [weak self] response in
    let data = response.data
})
```

### JSON `String`

```swift
dispatcher?.send(request).deserializeJSONString().success({ [weak self] response in
    let data = response.data
})
```

### `Decodable`

```swift
dispatcher?.send(request).deserializeDecodable().success({ [weak self] response in
    let decodable = response.data
})
```

### `MapDecodable`
MapCodableKit is a convenience frameworks that handles JSON deserialization. More information on this library can be found [here](https://github.com/cuba/MapCodableKit). It is especially useful if you want to reserve Codable for auxillary serialization. MapCodableKit allows you to deserialize nested objects.

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
Under the hood, NetworkKit uses a simple strongly typed implementation of a Promise.  This allows you to be as flexible as you want.

We promise to give you full documentation on these promises soon :)


## Dependencies

NetworkKit uses [MapCodableKit](https://github.com/cuba/MapCodableKit) for serialization.

## Credits

NetworkKit is owned and maintained by Jacob Sikorski.

## License

NetworkKit is released under the MIT license. [See LICENSE](https://github.com/cuba/NetworkKit/blob/master/LICENSE) for details
