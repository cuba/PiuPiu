[![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=592348f0b74ee700016fbbe6&branch=master&build=latest)](https://dashboard.buddybuild.com/apps/592348f0b74ee700016fbbe6/build/latest?branch=master)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20watchos%20%7C%20tvos-lightgray.svg?style=flat)](https://dashboard.buddybuild.com/apps/592348f0b74ee700016fbbe6/build/latest?branch=master)

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Credits](#credits)
- [License](#license)

## Features

- [x] A wrapper around Alamofire
- [x] Uses ObjectMapper for object deserialization
- [x] Easy integration
- [x] Handles common http errors

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
github "cuba/NetworkKit" ~> 1.0
```

Run `carthage update` to build the framework and drag the built `NetworkKit.framework` into your Xcode project.

## Usage

### Implementing the server provider

```swift
extension ViewController: ServerProvider {
    var baseURL: URL {
        return URL(string: "https://example.com")!
    }
}
```

### Initialization

```swift
let dispatcher = NetworkDispatcher(serverProvider: self)
serializer = NetworkSerializer(dispatcher: dispatcher)
```

### Basic usage (without serialization)

```swift
let request = JSONRequest(method: .get, path: "/posts/1")

serializer.send(request, successHandler: { (data: Any?) in
    print(data)
}, errorHandler: { error in
    print(error.localizedDescription)
}, completionHandler: {
    // perform some action at the end of the request
    // (Such as hide the activity indicator)
})
```

### Advanced usage

```swift
let request = JSONRequest(method: .get, path: "/posts")

serializer.send(request, successHandler: { (posts: [Posts]) in
    print(posts)
}, errorHandler: { error in
    print(error.localizedDescription)
}, completionHandler: {
    // perform some action at the end of the request
    // (Such as hide the activity indicator)
})
```

## Credits

NetworkKit is owned and maintained by Jacob Sikorski.

## License

NetworkKit is released under the MIT license. [See LICENSE](https://github.com/cuba/NetworkKit/blob/master/LICENSE) for details
