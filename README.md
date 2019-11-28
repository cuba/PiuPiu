[![Swift 5](https://img.shields.io/badge/swift-5-lightgrey.svg?style=for-the-badge)](https://swift.org)
![iOS 9+](https://img.shields.io/badge/iOS-9-lightgrey.svg?style=for-the-badge)
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
- [Transforms](#transforms)
- [Memory Managment](#memory-managment)
- [Mock Dispatcher](#mock-dispatcher)
- [Dependencies](#dependencies)
- [Credits](#credits)
- [License](#license)

## Updates

### 1.4.0
* Change `Request` protocol to return a `URLRequest`
* Replace  `Dispatcher` and `NetworkDispatcher` with `RequestSerializer`. 
* Callbacks will only be triggered once.  Once a callback is triggered, its reference is released (nullified).
  * This is to prevent memory leaks.
* Added `DataDispatcher`, `UploadDispatcher`, and `DownloadDispatcher` protocols which use a basic `URLRequest`.
  * Added `URLRequestDispatcher` class which implements all 3 protocols.
  * Added weak callbacks on dispatchers including the `MockURLRequestDispatcher`. You must now have a reference to your dispatcher.
  * Requests are cancelled when the dispatcher is de-allocated.
* Added `cancellation` callback to `ResponseFuture`. 
  * This may be manually triggered using `cancel` or is or is manually triggered when a nil is returned in any `join` (series only), `then` or `replace` or `action` (`init`) callback.
  * This callback does not cancel the actual requests but simply stops any further execution of the `ResponseFuture` after its final `cancellation` and `completion` callback.
* Added a parallel `join` callback that does not pass a response object. This calback is non-escaping.
* Slightly better multi-threading support.
  * by default, `then` is triggered on a background thread.
  * `success`, `response`, `error`, `completion`, and `cancellation` callbacks are always syncronized on the main thread.
* Add progress updates via the `progress` callback.
* Add better request mocking tools via the `MockURLRequestDispatcher`.

### 1.3.0
* Rename `PewPew` to `PiuPiu`
  * To handle this migration, replace all `import PewPew` with `import PiuPiu`
* Fix build for Carthage
* Delete unnecessary files

### 1.2.0
* Make `URLRequestProvider` return an optional URL.  This will safely handle invalid URLs instead of forcing the developer to use a !.
* Add JSON array serialization method to BasicRequest

### 1.1.0
Removed default translations.

### 1.0.1 
Fixed crash when translating caused by renaming the project.

## Features

- [x] A wrapper around network requests
- [x] Uses `Futures` (ie. `Promises`) to allow scalablity and dryness
- [x] Convenience methods for deserializing Decodable and JSON
- [x] Easy integration
- [x] Handles common http errors
- [x] Strongly typed and safely unwrapped responses
- [x] Clean!

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
github "cuba/PiuPiu" ~> 1.4
```

Run `carthage update` to build the framework and drag the built `PiuPiu.framework` into your Xcode project.

### Cocoapods

To integrate PiuPiu into your project using Cocoapods, specify it in your `Podfile`:

```bash
pod 'PiuPiu', '~> 1.4'
```

## Usage

### 1. Import `PiuPiu` into your file

```swift
import PiuPiu
```

### 2. Instantiate a  Dispatcher

All requests are made through a dispatcher.  There are 3 protocols for dispatchers:
* `DataDispatcher`: Performs standard http requests and returns a `ResponseFuture` that contains a `Response<Data?>` object. Can also be used for uploading data.
* `DownloadDispatcher`: For downloading data.  It returns a `ResponseFuture` that contains only a `Data` object.
* `UploadDispatcher`: For uploading data. Can usually be replaced with a `DataDispatcher`, but offers a few upload specific niceties like better progress updates. 

For convenience, a `URLRequestDispatcher` is provided implementing all 3 protocols.

```swift
class ViewController: UIViewController {
    private let dispatcher = URLRequestDispatcher()
    
    // ... 
}
```

You should have a strong reference to this object as it is held on weakly by your callbacks.

### 3. Making a request.

```swift
let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
let request = URLRequest(url: url, method: .get)

dispatcher.dataFuture(from: request).response({ response in
    // Handles any responses including negative responses such as 4xx and 5xx

    // The error object is available if we get an
    // undesirable status code such as a 4xx or 5xx
    if let error = response.error {
        // Throwing an error in any callback will trigger the `error` callback.
        // This allows us to pool all failures in one place.
        throw error
    }

    let post = try response.decode(Post.self)
    // Do something with our deserialized object
    // ...
    print(post)
}).error({ error in
    // Handles any errors during the request process,
    // including all request creation errors and anything
    // thrown in the `then` or `success` callbacks.
}).completion({
    // The completion callback is guaranteed to be called once
    // for every time the `start` method is triggered on the future.
}).send()
```

**NOTE**: Nothing will happen if you don't call `start()`.

### 4. (Optional) Separating concerns and transforming the future

*Pun not indended (honestly)*

Now lets move the part of the future that decodes our object to another method.  This way, our business logic is not mixed up with our serialization logic.
One of the great thing about using futures is that we can return them!

Lets create a method similar to this:

```swift
private func getPost(id: Int) -> ResponseFuture<Post> {
    // We create a future and tell it to transform the response using the
    // `then` callback. After this we can return this future so the callbacks will
    // be triggered using the transformed object. We may re-use this method in different
    return dispatcher.dataFuture(from: {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!
        return URLRequest(url: url, method: .get)
    }).then({ response -> Post in
        if let error = response.error {
            // The error is available when a non-2xx response comes in
            // Such as a 4xx or 5xx
            // You may also parse a custom error object here.
            throw error
        } else {
            // Return the decoded object. If an error is thrown while decoding,
            // It will be caught in the `error` callback.
            return try response.decode(Post.self)
        }
    })
}
```

**NOTE**: We intentionally did not call `start()` in this case. 

Then we can simply call it like this:

```swift
getPost(id: 1).response({ post in
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
dispatcher.dataFuture(from: {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
    return URLRequest(url: url, method: .get)
}).then({ response -> Post in
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

#### `response` or `success` callback

The `response` callback is triggered when the request is recieved and no errors are thrown in any chained callbacks (such as `then` or `join`).
At the end of the callback sequences, this gives you exactly what your transforms "promised" to return.

```swift
dispatcher.dataFuture(from: request).response({ response in
    // Triggered when a response is recieved and all callbacks succeed.
})
```

**NOTE**:  This method should **ONLY** be called **ONCE**.

#### `error` callback

Think of this as a `catch` on a `do` block. From the moment you trigger `send()`, the error callback is triggered whenever something is thrown during the callback sequence. This includes errors thrown in any other callback.

```swift
dispatcher.dataFuture(from: request).error({ error in
    // Any errors thrown in any other callback will be triggered here.
    // Think of this as the `catch` on a `do` block.
})
```

**NOTE**:  This method should **ONLY** be called **ONCE**.

#### `completion` callback

The completion callback is always triggered at the end after all `ResponseFuture` callbacks once every time `send()` or `start()` is triggered.

```swift
dispatcher.dataFuture(from: request).completion({
    // The completion callback guaranteed to be called once
    // for every time the `send` or `start` method is triggered on the callback.
})
```

**NOTE**:  This method should **ONLY** be called **ONCE**.

#### `then` callback

This callback transforms the `response` type to another type. This operation is done on a background queue so heavy operations won't lock your main queue. 

**WARNING**: You should avoid calling self in this callback . Use it solely for transforming the future.

```swift
dispatcher.dataFuture(from: request).then({ response -> Post in
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
dispatcher.dataFuture(from: request).then({ response -> Post in
    return try response.decode(Post.self)
}).replace({ [weak self] post -> ResponseFuture<EnrichedPost> in
    // Perform some operation operation that itself requires a future
    // such as something heavy like markdown parsing.
    return self?.enrich(post: post)
}).response({ enrichedPost in
    // The final response callback has the enriched post.
})
```

**NOTE**: You can return nil to stop the request process.  Useful when you want a weak self. 

#### `join` callback

This callback transforms the future to another type containing its original results plus the results of the returned callback.
This callback comes with 2 flavors: parallel and series.

##### Series `join`

The series join waits for the first respons and passes it to the callback so you can make requests that depend on that response.

```swift
dispatcher.dataFuture(from: {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
    return URLRequest(url: url, method: .get)
}).then({ response in
    // Transform this response so that we can reference it in the join callback.
    return try response.decode(Post.self)
}).join({ [weak self] post -> ResponseFuture<User>? in
    guard let self = self else {
        // We used [weak self] because our dispatcher is referenced on self.
        // Returning nil will cancel execution of this promise
        // and triger the `cancellation` and `completion` callbacks.
        // Do this check to prevent memory leaks.
        return nil
    }

    // Joins a future with another one returning both results.
    // The post is passed so it can be used in the second request.
    // In this case, we take the user ID of the post to construct our URL.
    let url = URL(string: "https://jsonplaceholder.typicode.com/users/\(post.userId)")!
    let request = URLRequest(url: url, method: .get)

    return self.dispatcher.dataFuture(from: request).then({ response -> User in
        return try response.decode(User.self)
    })
}).success({ post, user in
    // The final response callback includes both results.
    expectation.fulfill()
}).send()
```

**NOTE**: You can return nil to stop the request process.  Useful when you want a weak self.

##### Parallel `join` callback

This callback does not wait for the original request to complete, and executes right away. It is useful to series calls.

```swift
dispatcher.dataFuture(from: {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
    return URLRequest(url: url, method: .get)
}).then({ response in
    return try response.decode([Post].self)
}).join({ () -> ResponseFuture<[User]> in
    // Joins a future with another one returning both results.
    // Since this callback is non-escaping, you don't have to use [weak self]
    let url = URL(string: "https://jsonplaceholder.typicode.com/users")!
    let request = URLRequest(url: url, method: .get)

    return self.dispatcher.dataFuture(from: request).then({ response -> [User] in
        return try response.decode([User].self)
    })
}).success({ posts, users in
    // The final response callback includes both results.
    expectation.fulfill()
}).send()
```

**NOTE**: This callback will execute right away (it is non-escaping). `[weak self]` is therefore not necessary.

#### `send` or `start`

This will start the `ResponseFuture`. In other words, the `action` callback will be triggered and the requests will be sent to the server. 

**NOTE**: If this method is not called, nothing will happen (no request will be made).
**NOTE**: This method should **ONLY** be called **AFTER** declaring all of your callbacks (`success`, `failure`, `error`, `then` etc...)

### Creating your own `ResponseFuture`

You can create your own ResponseFuture for a variety of reasons. This can be used on another future's `join` or `replace` callback for some nice chaining.

Here is an example of a response future that does an expesive operation in another thread.

```
return ResponseFuture<UIImage>(action: { future in
    // This is an example of how a future is executed and fulfilled.
    DispatchQueue.global(qos: .background).async {
        // lets make an expensive operation on a background thread.
        // The success and progress and error callbacks will be synced on the main thread
        // So no need to sync back to the main thread.

        do {
            // Do an expensive operation here ....
            let resizedImage = try image.resize(ratio: 16/9)

            // If possible, we can send smaller progress updates
            // Otherwise it's a good idea to send 1 to indicate this task is all finished.
            // Not sending this won't cause any harm but your progress callback will not be triggered as a result of this future.
            future.update(progress: 1)
            future.succeed(with: resizedImage)
        } catch {
            future.fail(with: error)
        }
    }
})
```

**NOTE** You can also use the `then` callback of an existing future which is performed on a background thread.

## Encoding

PiuPiu has some convenience methods for you to encode objects into JSON and add them to the `BasicRequest` object.

### Encode JSON `String`

```
request.setJSONBody(string: jsonString, encoding: .utf8)
```

### Encode JSON Object

```
let jsonObject: [String: Any?] = [
    "id": "123",
    "name": "Kevin Malone"
]

try request.setJSONBody(jsonObject: jsonObject)
```

### Encode `Encodable`

```
try request.setJSONBody(encodable: myCodable)
```

### Wrap Encoding In a ResponseFuture

It might be beneficial to wrap the Request creation in a ResponseFuture. This will allow you to:
1. Delay the request creation at a later time when submitting the request.
2. Combine any errors thrown while creating the request in the error callback.

```swift
dispatcher.dataFuture(from: {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
    var request = URLRequest(url: url, method: .post)
    try request.setJSONBody(post)
    return request
}).error({ error in
    // Any error thrown while creating the request will trigger this callback.
}).send()
```

## Decoding

### Unwrapping `Data`

This will unwrap the data object for you or throw a ResponseError if it not there. This is convenent so that you don't have to deal with those pesky optionals. 

```swift
dispatcher.dataFuture(from: request).response({ response in
    let data = try response.unwrapData()

    // do something with data.
    print(data)
}).error({ error in 
    // Triggered when the data object is not there.
}).send()
```

### Decode `String`

```swift
dispatcher.dataFuture(from: request).response({ response in
    let string = try response.decodeString(encoding: .utf8)

    // do something with string.
    print(string)
}).error({ error in
    // Triggered when decoding fails.
}).send()
```

### Decode `Decodable`

```swift
dispatcher.dataFuture(from: request).response({ response in
    let posts = try response.decode([Post].self)

    // do something with the decodable object.
    print(posts)
}).error({ error in
    // Triggered when decoding fails.
}).send()
```

## Transforms

Transforms let you handle custom objects that are not `Encodable` or `Decodable` or if the default `Encodable` or `Decodable` logic on the object does not work for you. 

For example, let's say we want to change how we encode a `TimeZone`. So we can use the included `DateTransform` object like this:

```swift
struct ExampleModel: Codable {
    enum CodingKeys: String, CodingKey {
        case startDate
    }
    
    /// A formatter using the following format: `yyyy-MM-dd'T'HH:mm:ssZZZZZ`
    private static let formatter: DateFormatter = {
        let rfc3339DateFormatter = DateFormatter()
        rfc3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        rfc3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        rfc3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return rfc3339DateFormatter
    }()
    
    let startDate: Date
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateTransform = DateTransform(formatter: ExampleModel.formatter)
        self.startDate = try container.decode(using: dateTransform, forKey: .startDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let dateTransform = DateTransform(formatter: ExampleModel.formatter)
        try container.encode(startDate, forKey: .startDate, using: dateTransform)
    }
}
```

Notice that we are passing the `DateTransform(formatter:)` to the decode and encode methods.  This works for  `encode`, `encodeIfPresent`, `decode` and `decodeIfPresent`

### Custom transforms

We can create our own custom transforms by implementing the  `EncodingTransform` or `DecodingTrasform` protocols.

```swift
public protocol EncodingTransform {
    associatedtype ValueSource
    associatedtype JSONDestination: Encodable
    
    func transform(value: Self.ValueSource) throws -> Self.JSONDestination
}

public protocol DecodingTransform {
    associatedtype JSONSource: Decodable
    associatedtype ValueDesitination
    
    func transform(json: Self.JSONSource) throws -> Self.ValueDesitination
}
```

`EncodingTransform` is used when encoding and the `DecodingTransform` is used when decoding. You could also implement both by conforming to the `Transform` protocol. 

There are many use cases for this but the follwing are a few examples:

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
    
    public enum TransformError: Error {
        case invalidDateFormat(expectedFormat: String, received: String)
    }
    
    public func transform(json: String) throws -> Date {
        guard let date = formatter.date(from: json) else {
            throw TransformError.invalidDateFormat(expectedFormat: formatter.dateFormat, received: json)
        }
        
        return date
    }
    
    public func transform(value: Date) throws -> String {
        return formatter.string(from: value)
    }
}
```

### Included Transforms

The following transforms are included:

#### DateTransform

Converts a `String` to a `Date` and vice versa using a custom formatter.

#### TimeZoneTransform

Converts a time zone identifier (example: `America/Montreal`) to a `TimeZone` and vice versa.

#### URLTransform

Converts a URL `String` (example: `https://example.com`) to a `URL` object and vice versa. 

## Memory Managment

The `ResponseFuture` may have 3 types of strong references: 
1. The system may have a strong reference to the `ResponseFuture` after `send()` is called. This reference is temporary and will be dealocated once the system returns a response. This will never create a circular reference but as the future is held on by the system, it will not be released until **AFTER** a response is recieved or an error is triggered.
2. Any callback that references `self` has a strong reference to `self` unless `[weak self]` is explicitly specified.
3. The developer's own strong reference to the `ResponseFuture`.

### Strong callbacks

When **ONLY**  `1` and `2` applies to your case, a temporary circular reference is created until the future is resolved. You may wish to use `[weak self]` in this case but it is not necessary.

```swift
dispatcher.dataFuture(from: request).then({ response -> [Post] in
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
dispatcher.dataFuture(from: request).success({ response in
    // We are foce unwrapping a text field! DO NOT DO THIS!
    let textField = self.textField!

    // If we dealocated textField by the time the 
    // response comes back, a crash will occur
    textField.text = "Success"
}).send()
```

You will have crashes if you force unwrap anything in your callbacks (i.e. usign a `!`).  We suggest you **ALWAYS** avoid force unwrapping anything in your callbacks. 

Always unwrap your objects before using them. This includes any `IBOutlet`s that the system generates. Use a guard, Use an assert. Use anything but a `!`.

## Mock Dispatcher

Testing network calls is always a pain.  That's why we included the `MockURLRequestDispatcher`.  It allows you to simulate network responses without actually making network calls.

Here is an example of its usage:

```swift
private let dispatcher = MockURLRequestDispatcher(delay: 0.5, callback: { request in
    if let id = request.integerValue(atIndex: 1, matching: [.constant("posts"), .wildcard(type: .integer)]) {
        let post = Post(id: id, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        return try Response.makeMockJSONResponse(with: request, encodable: post, statusCode: .ok)
    } else if request.pathMatches(pattern: [.constant("posts")]) {
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        return try Response.makeMockJSONResponse(with: request, encodable: [post], statusCode: .ok)
    } else {
        throw ResponseError.notFound
    }
})
```

**NOTE**: You should have a strong reference to your dispatcher and a weak reference to `self` in the callback

## Future Features

- [x] Parallel calls
- [x] Sequential calls
- [x] A more generic dispatcher. The response object is way too specific
- [x] Better multi-threading support
- [x] Request cancellation

## Dependencies

PiuPiu includes...nothing. This is a light-weight library.

## Credits

PiuPiu is owned and maintained by Jacob Sikorski.

## License

PiuPiu is released under the MIT license. [See LICENSE](https://github.com/cuba/PiuPiu/blob/master/LICENSE) for details
