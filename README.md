[![Swift 5](https://img.shields.io/badge/swift-5-lightgrey.svg?style=for-the-badge)](https://swift.org)
![iOS 8+](https://img.shields.io/badge/iOS-8-lightgrey.svg?style=for-the-badge)
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
- [Memory Managment](#memory-managment)
- [Custom Encoding](#custom-encoding)
- [Custom Decoding](#custom-decoding)
- [Mock Dispatcher](#mock-dispatcher)
- [Dependencies](#dependencies)
- [Credits](#credits)
- [License](#license)

## Updates

### 1.4.0
* Remove Request, Dispatcher, NetworkDispatcher and ServerProvider. Should use DataDispatcher, UploadDispatcher, and DownloadDispatcher which use a basic URLRequest.
  * If you need to re-implement NetworkDispatcher and (Dispatcher) yourself and just delegate the methods to the provided URLRequestDispatcher.
* Added `cancellation` callback which may be manually called or is triggered when a nil is returned in `join` (series only), `then` or `replace` callbacks.
* Added a parallel `join` callback that does not pass a response object.
* Slightly better multi-threading support.
  * by default, `then` is triggered on a background thread.
  * `success`, `response`, `error`, `completion`, and `cancellation` callbacks are always syncronized on the main thread.
* Add progress updates.

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

## Why Futures?
Most of us are used to using callbacks or delegates for our networking calls. And that's fine for simple applications. But as your applicaiton grows, you will quickly realize a few drawbacks to this simple approach.  Here are a few reasons why futures are the way to go:

1. They are extensible: Because they are objects, they are extensible. Traditionally you would add helper methods on delegates and callbacks or convenience methods on callbacks. Helper methods, although useful, feel a little bit dislocated. Helper methods on the other hand tend to be too specific and speghettify your code. Methods on the object itself, make it easier to debug, develop, name and document because they are context sensitive. And this will help write code, understand code and debug issues.  Plus, It's also nice to just press a `.` on your keyboard and see what methods you get instead of remembering the name of that helper class that handles the specific response object your receieved.
2. Asyncronous Do/Catch: Anything you throw in the future's callbacks will be handled. This is normally tedious in delegates and callbacks as they always have to be wrapped around a do/catch block. Futures have a sort of do/catch mechanism for asyncronous tasks.
3. Multithreading: Futures offer better multithreading support because they have predefined and useful functions that work on seperate threads. So don't worry about parsing your data in the `then` callback. It won't lock your main thread.
4. One generic to rule them all: Futures use a generic result object. This means a future can be used for anything.  Network calls or heavy tasks: It doesn't matter.
5. Better compiler support: Forgot to call your callback? You don't have to worry about it with Futures because they are called for you as soon as you trigger `send()`  or `start()`. And if you forget to call `send()`, your compiler will remind you.
6. Pass them around: You can pass futures around and handle them where you need to.
7. Strongly typed: The object you recieve in the end is strongly typed so you don't need to cast or fail.  It will hande this for you.

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

This callback transforms the future to another type containing its original results plus the results of the returned callback. This allows us to make asyncronous calls in series.

```swift
dispatcher.dataFuture(from: request).then({ response -> Post in
    return try response.decode(Post.self)
}).join({ [weak self] post -> ResponseFuture<User> in
    // Joins a future with another one returning both results
    return self?.fetchUser(forId: post.userId)
}).response({ post, user in
    // The final response callback includes both results.
})
```

**NOTE**: You can return nil to stop the request process.  Useful when you want a weak self.

#### `send` or `start`

This will start the `ResponseFuture`. In other words, the `action` callback will be triggered and the requests will be sent to the server. 

**NOTE**: If this method is not called, nothing will happen (no request will be made).
**NOTE**: This method should **ONLY** be called **AFTER** declaring all of your callbacks (`success`, `failure`, `error`, `then` etc...)
**NOTE**:  This method should **ONLY** be called **ONCE**.

### Creating your own ResponseFuture

You can create your own ResponseFuture for a variety of reasons. If you do, you will have all the benefits you have seen so far.

Here is an example of a response future that does decoding in another thread.

```
return ResponseFuture<[Post]>(action: { future in
    // This is an example of how a future is executed and
    // fulfilled.
    DispatchQueue.global(qos: .userInitiated).async {
        // lets make an expensive operation on a background thread.
        // The below is just an example of how you can parse on a seperate thread.

        do {
            // Do an expensive operation here ....
            let posts = try response.decode([Post].self)
            future.succeed(with: posts)
        } catch {
            // We should syncronize the error to the main thread.
            future.fail(with: error)
        }
    }
})
```

**NOTE** The future will syncronize the `succeed`, `fail` or `cancel` methods on the main thread.

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

## Future Features

- [x] Parallel calls
- [x] Sequential calls
- [x] A more generic dispatcher. The response object is way too specific.
- [x] Better multi-threading support

## Dependencies

PiuPiu includes...nothing. This is a light-weight library.

## Credits

PiuPiu is owned and maintained by Jacob Sikorski.

## License

PiuPiu is released under the MIT license. [See LICENSE](https://github.com/cuba/PiuPiu/blob/master/LICENSE) for details
