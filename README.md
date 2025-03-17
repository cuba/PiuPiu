[![Swift 5](https://img.shields.io/badge/swift-5-lightgrey.svg?style=for-the-badge)](https://swift.org)
![iOS 9](https://img.shields.io/badge/iOS-9-lightgrey.svg?style=for-the-badge)
![MacOS 10.15](https://img.shields.io/badge/macos-10-lightgrey.svg?style=for-the-badge)
[![SPM](https://img.shields.io/badge/SPM-compatible-green.svg?style=for-the-badge)](https://swift.org/package-manager)
[![Carthage](https://img.shields.io/badge/carthage-compatible-green.svg?style=for-the-badge)](https://github.com/Carthage/Carthage)
[![GitHub](https://img.shields.io/github/license/mashape/apistatus.svg?style=for-the-badge)](https://github.com/cuba/PiuPiu/blob/master/LICENSE)
[![Build](https://img.shields.io/travis/com/cuba/PiuPiu/master.svg?style=for-the-badge)](https://app.travis-ci.com/github/cuba/PiuPiu)

![PiuPiu Logo](https://github.com/cuba/PiuPiu/blob/master/Example/Example/Assets.xcassets/AppIcon.appiconset/AppIcon_iPadProApp_83.5@2x.png?raw=true)


PiuPiu
============

PiuPiu adds the concept of `Futures` (aka: `Promises`) to iOS. It is intended to make networking calls cleaner and simpler and provides the developer with more customizability than any other networking framework.

**Q**: Why should I use this framework?
**A**: Because, you like clean code.

**Q**: Why the stupid name?
**A**: Because "piu piu" is the sound of lasers. And lasers are from the future.

**Q**: What sort of bear is best?
**A**: False! A black bear!

- [Updates](#updates)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Future](#future)
- [Encoding](#encoding)
- [Decoding](#decoding)
- [Transforms](#transforms)
- [Memory Managment](#memory-managment)
- [Mock Dispatcher](#mock-dispatcher)
- [Dependencies](#dependencies)
- [Credits](#credits)
- [License](#license)

## Updates
### 2.0.0
* Removed futures. This is now a library to add conveniences to existing swift concurrency
  * Mostly utilizing standard url methods 

## Features

- [x] A wrapper around network requests
- [x] Convenience methods for deserializing Decodable and JSON
- [x] Easy integration
- [x] Handles common http errors
- [x] Strongly typed and safely unwrapped responses
- [x] Clean!

## Installation

### SPM

PiuPiu supports SPM

## Usage

### 1. Import `PiuPiu` into your file

```swift
import PiuPiu
```

### 2. Instantiate a Dispatcher

All requests are made through a dispatcher. There are 3 protocols for dispatchers:
* `DataDispatcher`: Performs standard http requests and returns a `Response<Data?>` object.
* `DownloadDispatcher`: For downloading data. It returns a `Response<URL>` object.
* `UploadDispatcher`: For uploading data. It returns a `Response<Data?>` object. 

For convenience, a `URLRequestDispatcher` is provided implementing all 3 protocols.
For tests you can also use `MockURLRequestDispatcher` but you will have to provide your own mocks.

```swift
class ViewController: UIViewController {
    private let dispatcher = URLRequestDispatcher()
    
    // ... 
}
```

You should have a strong reference to this object.

### 3. Making a request
Here we have a complete request example, including error handling and decoding.


```swift
let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
let request = URLRequest(url: url, method: .get)
let response = try await dispatcher.data(from: request)
```

## Advanced Usage

### URLRequestAdapter

The `URLRequestAdapter` protocol allows you to change the request or perform some other task before dispatching it. 
This is useful for a number of cases including:

* Injecting authorization headers
* Modifying url's to point to some local (mock data)
* Logging the request

### URLResponseAdapter

Similar to the `URLRequestAdapter`, the `URLResponseAdapter` allows you to modify the response or perform some other task before returning the response.
This is useful for a number of cases including:

* Converting mock responses (pointing to local files) to fake `HTTPResponses` (very useful for mock data testing)
* Logging the response

## Decoding

### Unwrapping `Data`

This will unwrap the data object for you or throw a `ResponseError.unexpectedEmptyResponse` if it not there. This is convenient so that you don't have to deal with those pesky optionals.

```swift
let responseWithData = try response.ensureData()
let data = responseWithPosts.body
...
```

or 

```swift
let data = try response.unwrapData()
...
```

### Decode `String`
You can return a decodable object easily (make sure you ensure data first):

```swift
let string = try response.ensureData().decodeString(encoding: .utf8)
...
```

### Decode `Decodable`
You can return a decodable object easily:

```swift
let responseWithPosts = try await response.ensureDecoded([Post].self)
let posts = responseWithPosts.body
...
```

or

```swift
let posts = try await response.ensureData().decode([Post].self)
...
```

### Chaining
Decodes are chainable and you don't loose access to the underlying URLRequest/URLResponse object'

```
let decodedResponse = try await response
  .ensureHTTPResponse()
  .ensureValidResponse()
  .ensureData()
  .ensureDecoded([Post].self)
  
let posts = decodedResponse.body
let statusCode = decodedResponse.statusCode
...
```

## Transforms

Transforms let you handle custom objects that are not `Encodable` or `Decodable` or if the default `Encodable` or `Decodable` logic on the object does not work for you. 

For example, let's say we want to change how we encode a `TimeZone` so that it encodes or decodes a timezone identifier (example: `America/Montreal`). We can use the included `TimeZoneTransform` object like this:

```swift
struct ExampleModel: Codable {
    enum CodingKeys: String, CodingKey {
        case timeZoneId
    }
    
    let timeZone: TimeZone
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.timeZone = try container.decode(using: TimeZoneTransform(), forKey: .timeZoneId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timeZone, forKey: .timeZoneId, using: TimeZoneTransform())
    }
}
```

In the above example, we are passing the `TimeZoneTransform()` to the `decode` and `encode` methods because it conforms to both the `EncodingTransform` and `DecodingTransform` protocols. We can use the `EncodingTransform` and  `DecodingTransform` individually if we don't need to conform to both. If we want both, we can also use the `Transform` protocol which encompasses both. They are synonymous with `Encodable`, `Decodable` and `Codable`.

### Custom transforms

We can create our own custom transforms by implementing the  `EncodingTransform` or `DecodingTrasform` protocols.

```swift
public protocol EncodingTransform {
    associatedtype ValueSource
    associatedtype JSONDestination: Encodable
    
    func toJSON(Self.ValueSource, codingPath: [CodingKey]) throws -> Self.JSONDestination
}

public protocol DecodingTransform {
    associatedtype JSONSource: Decodable
    associatedtype ValueDestination
    
    func from(json: Self.JSONSource, codingPath: [CodingKey]) throws -> Self.ValueDestination
}
```

`EncodingTransform` is used when encoding and the `DecodingTransform` is used when decoding. You could also implement both by conforming to the `Transform` protocol. 

There are many use cases for this but the following are a few examples:

* Convert old DTO objects to newer objects.
* Different `Encoding` or `Decoding` strategies on the same object
* Filtering arrays

An example of this implementation can be seen on the included `DateTransform`:

```swift
public class DateTransform: Transform {
    public let formatter: DateFormatter
    
    public init(formatter: DateFormatter) {
        self.formatter = formatter
    }
    
    public func from(json: String, codingPath: [CodingKey]) throws -> Date {
        guard let date = formatter.date(from: json) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Could not convert `\(json)` to `Date` using formatter `\(String(describing: formatter))`"))
        }
        
        return date
    }
    
    public func toJSON(Date, codingPath: [CodingKey]) throws -> String {
        return formatter.string(from: value)
    }
}
```

### Included Transforms

The following transforms are included:

#### `DateTransform`

Converts a `String` to a `Date` and vice versa using a custom formatter.

#### `TimeZoneTransform`

Converts a time zone identifier (example: `America/Montreal`) to a `TimeZone` and vice versa.

#### `URLTransform`

Converts a URL `String` (example: `https://example.com`) to a `URL` object and vice versa. 

#### `IntFromStringTransform`

Converts a `String` to an `Int64` in both directions.

#### `StringFromIntTransform`

Converts an `Int64` (including `Int`) to a `String` in both directions.

#### `EmptyStringTransform` 

Will convert an empty string (`""`) to a nil.

NOTE: Using `decodeIfPresent` will result in a double optional (i.e. `??`). You can solve this by coalescing to a `nil`. For example: 

```swift
self.value = try container.decodeIfPresent(using: EmptyStringTransform(), forKey: .value) ?? nil
```

## Dependencies

PiuPiu includes...nothing. This is a light-weight library.

## Credits

PiuPiu is owned and maintained by Jacob Sikorski.

## License

PiuPiu is released under the MIT license. [See LICENSE](https://github.com/cuba/PiuPiu/blob/master/LICENSE) for details
