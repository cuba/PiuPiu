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

### 1.10.0
* Using `DispatchGroup` for parallel joins
* Removed deprecated methods on `ResponseFuture`
  * `public func replace<U>(_ successCallback: @escaping (T) throws -> ResponseFuture<U>?) -> ResponseFuture<U>`
  * `public func join<U>(_ callback: () -> ResponseFuture<U>) -> ResponseFuture<(T, U)>`
  * `public func nonFailing() -> ResponseFuture<SafeResponse<T>>`
  * `public func thenError<U>(_ callback: @escaping (SafeResponse<T>) throws -> U) -> ResponseFuture<U>`
  * `public func join<U>(_ callback: @escaping (T) throws -> ResponseFuture<U>?) -> ResponseFuture<(T, U)>`
* Removed methods for joining calls of the same type on a sequence (array) of futures
  * `func addingParallelResult(from callback: () -> ResponseFuture<T.Element>) -> ResponseFuture<[T.Element]>`
  * `func addingSeriesResult(from callback: @escaping (T) throws -> ResponseFuture<T.Element>?) -> ResponseFuture<[T.Element]>`
* Added an initalizer for joining many parallel calls on a sequence
* Rename `ResponseFuture` embedded type from `T` to `Success` (i.e. `ResponseFuture<Success>`)
* Rename `Response` embedded type from `T` to `Body` (i.e. `Response<Body>`)
* Rename `HTTPResponse` embedded type from `T` to `Body` (i.e. `HTTPResponse<Body>`)
* Rename `ResponseInterface` associated type from `T` to `Body`
* Localize HTTPError

### 1.9.0
* Removed `GroupedFailure`. First error triggered will fail the future. If you need access to the results use `safeParallelJoin` instead.
* Addes some more convenience "join" functions on `ResponseFuture`: `addingParallelNullableResult`, `addingSeriesNullableResult`, `safeParallelNullableJoin`, `safeSeriesNullableJoin`, `parallelNullableJoin`, and `seriesNullableJoin`
* Deprecated some `ResponseFuture` functions in favour of ones that take an explicit type
* Remove useless throwables that never threw anything
* Remove `MockDispatcherError` and use `ResponseError.noResponse` if no callback is set on `MockURLRequestDispatcher`

### 1.8.0
* Dropped `SafeResponse` in favour or `Result`
* Require `[CodingKey]` to be passed in to the `EncodingTransform` and `DecodingTransform` methods
* Replaced `func transform(value: Self.ValueSource)` with `func toJSON(_ value: Self.ValueSource, codingPath: [CodingKey])`
* Replaced `func transform(json: Self.JSONSource)` with `func from(json: Self.JSONSource, codingPath: [CodingKey])`
* Added `map`, `parallelJoin`, `seriesJoin`, `thenResult`, `safeResult`, `safeParallelJoin` and `safeSeriesJoin` callbacks to `ResponseFuture`
* Added `result` callback
* Added `addingParallelResult` and `addingSeriesResult` methods to `ResponseFutures` that encompass a `Sequence`
* Deprecated the `SafeResponse` enum and `fulfill`, `join` (series and parallel), `thenError`, `nonFailing` methods on `ResponseFuture`

### 1.7.0
* Added support for swift package manager

### 1.6.0
* Removed `progress` callback. This is now replaced with the `updated` callback which returns a `task`.
* Add helper methods for computing progress

### 1.5.0
* Download requests returns `Response` with temporary `URL` instead of `Data`
* Added `localizedDescription` to `StatusCode` which returns Apple's translated error message 
* Re-shuffled "Response" objects 
  * `Response#error` has been removed and replaced with `HTTPResponse#httpError`
  * `SuccessResponse` has been renamed to `HTTPResponse`
  * `ResponseInterface` returns `URLResponse` instead of `HTTPURLResponse`
  * `Response` returns `URLResponse` instead of `HTTPURLResponse` 
  * You need to manually convert a `Response` to an `HTTPResponse` first (see the [example](#making-a-request) below) 
* Errors have been re-organized.
  * `ResponseError` cases have been reduced to 4 and renamed to `HTTPError`
  * `HTTPError` cases contain more generic HTTP errors instead of specific HTTP errors based on status code.
  * `SerializationError` has been moved to `ResponseError` and 2 new cases have been added
* Error handling has been simplified
  * `JSONSerializer` errors no longer are wrapped by another error
  * `Decodable` errors are no longer wrapped


### 1.4.0
* Change `Request` protocol to return a `URLRequest`
* Replace  `Dispatcher` and `NetworkDispatcher` with `RequestSerializer`. 
* Callbacks will only be triggered once. Once a callback is triggered, its reference is released (nullified).
  * This is to prevent memory leaks.
* Added `DataDispatcher`, `UploadDispatcher`, and `DownloadDispatcher` protocols which use a basic `URLRequest`.
  * Added `URLRequestDispatcher` class which implements all 3 protocols.
  * Added weak callbacks on dispatchers including the `MockURLRequestDispatcher`. You must now have a reference to your dispatcher.
  * Requests are cancelled when the dispatcher is de-allocated.
* Added `cancellation` callback to `ResponseFuture`. 
  * This may be manually triggered using `cancel` or is or is manually triggered when a nil is returned in any `join` (series only), `then` or `replace` or `action` (`init`) callback.
  * This callback does not cancel the actual requests but simply stops any further execution of the `ResponseFuture` after its final `cancellation` and `completion` callback.
* Added a parallel `join` callback that does not pass a response object. This callback is non-escaping.
* Slightly better multi-threading support.
  * by default, `then` is triggered on a background thread.
  * `success`, `response`, `error`, `completion`, and `cancellation` callbacks are always synchronized on the main thread.
* Add progress updates via the `progress` callback.
* Add better request mocking tools via the `MockURLRequestDispatcher`.

### 1.3.0
* Rename `PewPew` to `PiuPiu`
  * To handle this migration, replace all `import PewPew` with `import PiuPiu`
* Fix build for Carthage
* Delete unnecessary files

### 1.2.0
* Make `URLRequestProvider` return an optional URL. This will safely handle invalid URLs instead of forcing the developer to use a !.
* Add JSON array serialization method to BasicRequest

### 1.1.0
Removed default translations.

### 1.0.1 
Fixed crash when translating caused by renaming the project.

## Features

- [x] A wrapper around network requests
- [x] Uses `Futures` (ie. `Promises`) to allow scalability and dryness
- [x] Convenience methods for deserializing Decodable and JSON
- [x] Easy integration
- [x] Handles common http errors
- [x] Strongly typed and safely unwrapped responses
- [x] Clean!

## Installation

### Carthage

NOTE: Carthage support will die since it no longer works with Catalyst

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate PiuPiu into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "cuba/PiuPiu" ~> 1.8
```

Run `carthage update` to build the framework and drag the built `PiuPiu.framework` into your Xcode project.

### SPM

PiuPiu supports SPM

### ~~Cocoapods~~

PiuPiu no longer supports cocoapods. Cocoapods is dying and is ugly to maintain. Use SPM. It's easy to use and maintain.

## Usage

### 1. Import `PiuPiu` into your file

```swift
import PiuPiu
```

### 2. Instantiate a Dispatcher

All requests are made through a dispatcher. There are 3 protocols for dispatchers:
* `DataDispatcher`: Performs standard http requests and returns a `ResponseFuture` that contains a `Response<Data?>` object. Can also be used for uploading data.
* `DownloadDispatcher`: For downloading data. It returns a `ResponseFuture` that contains only a `Data` object.
* `UploadDispatcher`: For uploading data. Can usually be replaced with a `DataDispatcher`, but offers a few upload specific niceties like better progress updates. 

For convenience, a `URLRequestDispatcher` is provided implementing all 3 protocols.
For tests you can also use `MockURLRequestDispatcher` but you will have to provide your own mocks.

```swift
class ViewController: UIViewController {
    private let dispatcher = URLRequestDispatcher()
    
    // ... 
}
```

You should have a strong reference to this object as it is held on weakly by your callbacks.

### 3. Making a request
Here we have a complete request example, including error handling and decoding.


```swift
let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
let request = URLRequest(url: url, method: .get)

dispatcher.dataFuture(from: request)
    .success { response in
        // Here we handle our response as long as nothing was thrown along the way
        // This method is always invoked on the main queue.
        
        // Here we check if we have an HTTP response.
        // Anything we throw in this method will be handled on the `error` callback.
        // If PiuPiu cannot create an http response, the method will throw an error.
        // Unhandled, it will just end up in our `error` callback.
        let httpResponse = try response.makeHTTPResponse()
        
        // We also ensure that our HTTP response is valid (i.e. a 1xx, 2xx or 3xx response)
        if let error = httpResponse.httpError {
            // HTTP errors are not thrown automatically so you get a chance to handle them
            // If we want it to be handled in our `error` callback, we simply just throw it
            throw error
        } else {
            // PiuPiu has a convenience method to decode `Decodable` objects
            self.post = try response.decode(Post.self)

            // now we can present our post
            // ...
        }
    }
    .error { error in
        // Here we handle any errors that were thrown along the way
        // This method is always invoked on the main queue.
        
        // This includes all errors thrown by PiuPiu during the request
        // creation/dispatching process as well as any network failures.
        // It also includes anything we threw in our previous callbacks
        // such as any decoding issues, http errors, etc.
        print(error)
    }
    .completion {
        // The completion callback is guaranteed to be called once
        // for every time the `start` method is triggered on the future
        // regardless of success or error.
        // It will always be the last callback to be triggered.
    }
    .send()
```

**NOTE**: Nothing will happen if you don't call `start()` or `send()`.

## Advanced Usage

### Separating concerns

Often times we want to separate our responses into different parts so we can handle them differently. We also want to decode on a background thread so that it doesn't make our UI choppy. We can do this using the `then` callback. 

Each `then` callback transforms the response and returns a new one.

```swift
dispatcher
    .dataFuture {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        return URLRequest(url: url, method: .get)
    }
    .then { response -> Post in
        // Attempt to get a http response
        let httpResponse = try response.makeHTTPResponse()
        
        // Check if we have any http error
        if let error = httpResponse.httpError {
            // Throwing an error in any callback will trigger the `error` callback.
            // This allows us to pool all failures in that callback if we want to
            throw error
        }
        
        // If we have no error, we just return the decoded object
        // If anything is thrown, it will be caught in the `error` callback.
        return try response.decode(Post.self)
    }
    .updated { task in
        // Sends task updates so you can perform things like progress updates
    }
    .success { post in
        // Handles any success responses.
        // In this case the object returned in the `then` method.
    }
    .error { error in
        // Handles any errors during the request process,
        // including all request creation errors and anything
        // thrown in the `then` or `success` callbacks.
    }
    .completion {
        // The completion callback guaranteed to be called once
        // for every time the `start` method is triggered on the callback.
        completionExpectation.fulfill()
    }
    .send()
```

**NOTE**: Nothing will happen if you don't call `start()` or `send()`.


### Re-usability

In the above example, we show a number of `then` callbacks to transform our response. In the first `then` callback we deal with common HTTP errors. In the other, we deal with with decoding a specific `Post` object. However none of the code is yet re-usable. 

#### Method chaining (not recommended)

One way to do that is through chaining.

```swift
/// This method returns an HTTP response containing a decoded `Post` object
func getPost(id: Int) -> ResponseFuture<HTTPResponse<Post>> {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
    let request = URLRequest(url: url, method: .get)
    
    return getHTTPResponse(from: request)
        .then(on: DispatchQueue.global(qos: .background)) { httpResponse -> HTTPResponse<Post> in
            // Here we decode the http response into an object using `Decodable`
            // We use the `background` thread because decoding can be somewhat intensive.
            
            // WARNING: Do not use `self` here as
            // this `callback` is being invoked on a `background` queue
            
            // PiuPiu has a convenience method to decode `Decodable` objects
            return try httpResponse.decoded(Post.self)
        }
}

/// This method handles common HTTP errors and returns an HTTP response.
private func getHTTPResponse(from request: URLRequest) -> ResponseFuture<HTTPResponse<Data?>> {
    return dispatcher.dataFuture(from: request)
        .then { response -> HTTPResponse<Data?> in
            // In this callback we handle common HTTP errors
            
            // Here we check if we have an HTTP response.
            // Anything we throw in this method will be handled on the `error` callback.
            // If PiuPiu cannot create an http response, method will throw an error.
            // Unhandled, it will just end up in our `error` callback.
            let httpResponse = try response.makeHTTPResponse()
            
            // We also ensure that our HTTP response is valid (i.e. a 1xx, 2xx or 3xx response)
            // because there is no point deserializing anything unless we have a valid response
            if let error = httpResponse.httpError {
                // HTTP errors are not thrown automatically so you get a chance to handle them
                // If we want it to be handled in our `error` callback, we simply just throw it
                throw error
            }
            
            // Everything is good, so we just return our HTTP response.
            return httpResponse
        }
}
```

To use this we can just simply call `getPost` like so:

```swift
getPost(id: 1)
    .success { response in
        // This method is always invoked on the main queue.
        
        // At this point, we know all of our errors are handled
        // and our object is deserialized
        let post = response.data

        // Do something with our deserialized object ...
        print(post)
        
    }
    .error { error in
        // This method is always invoked on the main queue.
    }
    .completion {
        // The completion callback is guaranteed to be called once
        // for every time the `start` method is triggered on the future.
    }
    .send()
```

This concept should not be too new for us since we're probably done similar type of chaining using regular callbacks. Our method `getPost` creates the request and parses a `Post` object. Internally it calls `getHTTPResponse` which dispatches our request and handles `HTTP` errors. 

But we don't need to nest callbacks anymore. It makes our code flatter and easier to follow (once we get used to it).

#### Extensions (recommended)

Another way to handle common logic is to add extensions to futures. 

We can perform our `getHTTPResponse` logic inside an extension such as this:

```swift
extension ResponseFuture where Success == Response<Data?> {
    /// This method handles common HTTP errors and returns an HTTP response.
    var validHTTPResponse: ResponseFuture<HTTPResponse<Data?>> {
        return then(HTTPResponse<Data?>.self) { response -> HTTPResponse<Data?> in
            // In this callback we handle common HTTP errors
            
            // Here we check if we have an HTTP response.
            // Anything we throw in this method will be handled on the `error` callback.
            // If PiuPiu cannot create an http response, method will throw an error.
            // Unhandled, it will just end up in our `error` callback.
            let httpResponse = try response.makeHTTPResponse()
            
            // We also ensure that our HTTP response is valid (i.e. a 1xx, 2xx or 3xx response)
            // because there is no point deserializing anything unless we have a valid response
            if let error = httpResponse.httpError {
                // HTTP errors are not thrown automatically so you get a chance to handle them
                // If we want it to be handled in our `error` callback, we simply just throw it
                throw error
            }
            
            // Everything is good, so we just return our HTTP response.
            return httpResponse
        }
    }
}
```

Here we took a slightly different approach. We changed our method to support **any** `Decodable` object. In other words, this method allows us to convert **any** `ResponseFuture` containing an `HTTPResponse<Data?>` object to one that contains **any** `Decodable` object. 

In addition, we do the decoding on a background thread so it doesn't stall our UI while doing so.

And now, not only can we use these two extensions on our `getPost` call, but we can also use it on other calls such as this `getUser` call such as this one:

```swift
/// This method returns an HTTP response containing a decoded `Post` object
func getPost(id: Int) -> ResponseFuture<HTTPResponse<Post>> {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
    let request = URLRequest(url: url, method: .get)
    
    return dispatcher.dataFuture(from: request)
        .validHTTPResponse
        .decoded(Post.self)
}

/// This method returns an HTTP response containing a decoded `User` object
func getUser(id: Int) -> ResponseFuture<HTTPResponse<User>> {
    let url = URL(string: "https://jsonplaceholder.typicode.com/users/1")!
    let request = URLRequest(url: url, method: .get)
    
    return dispatcher.dataFuture(from: request)
        .validHTTPResponse
        .decoded(User.self)
}
```

NOTE: `decoded` function is already provided by `PiuPiu`.

But these are just some examples. There is an infinite number of combinations you can create. This is why futures are far superior to using simple callbacks.

## Future

You've already seen that a `ResponseFuture` allows you to chain your callbacks, transform the response object and pass it around. But besides the simple examples above, there is so much more you can do to make your code amazingly clean!

### Callbacks

#### `success` callback

The `success` callback is triggered when the request is received and no errors are thrown in any chained callbacks (such as `then` or `join`).
At the end of the callback sequences, this gives you exactly what your transforms "promised" to return.

```swift
dispatcher.dataFuture(from: request).success { response in
    // Triggered when a response is received and all callbacks succeed.
}
```

**NOTE**:  This method should **ONLY** be called **ONCE**.

#### `error` callback

Think of this as a `catch` on a `do` block. From the moment you trigger `send()`, the error callback is triggered whenever something is thrown during the callback sequence. This includes errors thrown in any other callback.

```swift
dispatcher.dataFuture(from: request).error { error in
    // Any errors thrown in any other callback will be triggered here.
    // Think of this as the `catch` on a `do` block.
}
```

**NOTE**:  This method should **ONLY** be called **ONCE**.

#### `completion` callback

The completion callback is always triggered at the end after all `ResponseFuture` callbacks once every time `send()` or `start()` is triggered.

```swift
dispatcher.dataFuture(from: request).completion {
    // The completion callback guaranteed to be called once
    // for every time the `send` or `start` method is triggered on the callback.
}
```

**NOTE**:  This method should **ONLY** be called **ONCE**.

#### `then` or `map` callback

This callback transforms the `response` type to another type. This operation is done on a background queue so heavy operations won't lock your main queue. 

You may want to specify the return type in the method to make it easier on your compiler.

You may also specify the thread to use.

**WARNING**: You should avoid calling self in this callback if you're not specifying the `main` thread.

```swift
dispatcher.dataFuture(from: request).then { response -> Post in
    // The `then` callback transforms a successful response to another object
    // You can return any object here and this will be reflected on the `success` callback.
    return try response.decode(Post.self)
}.success { post in
    // Handles any success responses.
    // In this case the object returned in the `then` method.
}
```

#### `replace` callback

This callback transforms the future to another type using another callback. This allows us to make asynchronous calls inside our callbacks.

```swift
dispatcher.dataFuture(from: request).then { response -> Post in
    return try response.decode(Post.self)
}.replace(EnrichedPost.self) { [weak self] post in
    // Perform some operation operation that itself requires a future
    // such as something heavy like markdown parsing.
    return self?.enrich(post: post)
}.success { enrichedPost in
    // The final response callback has the enriched post.
}
```

**NOTE**: You can return nil to stop the request process. Useful when you want a weak self. 

#### `parallelJoin` or `seriesJoin` callbacks

This callback transforms the future to another type containing its original results plus the results of the returned callback.
This callback comes with 2 flavours: parallel and series. You may also use `parallelJoin` and `seriesJoin` which do the same thing

##### `seriesJoin` callback

The series join waits for the first response and passes it to the callback so you can make requests that depend on that response but is obviously much slower than making parallel calls.

```swift
dispatcher.dataFuture() {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
    return URLRequest(url: url, method: .get)
}.then { response in
    // Transform this response so that we can reference it in the join callback.
    return try response.decode(Post.self)
}.seriesJoin(User.self) { [weak self] post in
    guard let self = self else {
        // We used [weak self] because our dispatcher is referenced on self.
        // Returning nil will cancel execution of this promise
        // and trigger the `cancellation` and `completion` callbacks.
        // Do this check to prevent memory leaks.
        return nil
    }

    // Joins a future with another one returning both results.
    // The post is passed so it can be used in the second request.
    // In this case, we take the user ID of the post to construct our URL.
    let url = URL(string: "https://jsonplaceholder.typicode.com/users/\(post.userId)")!
    let request = URLRequest(url: url, method: .get)

    return self.dispatcher.dataFuture(from: request).then { response -> User in
        return try response.decode(User.self)
    }
}.success { post, user in
    // The final response callback includes both results.
    expectation.fulfill()
}.send()
```

**NOTE**: You can return nil to stop the request process. Useful when you want a weak self.

##### `parallelJoin` callback

This callback does not wait for the original request to complete, and executes right away. It is useful when you don't need to wait for some other data to comeback before making a request.

```swift
dispatcher.dataFuture() {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
    return URLRequest(url: url, method: .get)
}.then { response in
    return try response.decode([Post].self)
}.parallelJoin([User].self) {
    // Joins a future with another one returning both results.
    // Since this callback is non-escaping, you don't have to use [weak self]
    let url = URL(string: "https://jsonplaceholder.typicode.com/users")!
    let request = URLRequest(url: url, method: .get)

    return self.dispatcher.dataFuture(from: request).then { response -> [User] in
        return try response.decode([User].self)
    }
}.success { posts, users in
    // The final response callback includes both results.
    expectation.fulfill()
}.send()
```

**NOTE**: This callback will execute right away (it is non-escaping). `[weak self]` is therefore not necessary.

#### `result`

This is a callback that groups both the `success` and `failure` callbacks into one callback using `Result<Success, Failure>`. This is useful when you want to treat the success and failure under similar conditions.

#### `send` or `start`

This will start the `ResponseFuture`. In other words, the `action` callback will be triggered and the requests will be sent to the server. 

**NOTE**: If this method is not called, nothing will happen (no request will be made).
**NOTE**: This method should **ONLY** be called **AFTER** declaring all of your callbacks (`success`, `failure`, `error`, `then`, `seriesJoin`, `parallelJoin` etc...)

### Conveniences

There are also some conveniences build into PiuPiu futures that will make your life easier

#### `safeResult()`

The safe result is not useful in itself but very useful when you are joining requests. It will not cause all the requests to fail if this one future fails. 

But the result will be different. Instead of getting your object you will get a `Result<Success, Error>` object back.

Because this is so convenient (and often necessary), for parallel and series joins `safeParallelJoin` and `safeSeriesJoin` callbacks are also available.

#### `decoded`

Since decoding data is necessary, a convenience `decoded` method is added which will use the `Decodable` protocol. 

You may even provide your own custom `JSONDecoder`

### Creating your own `ResponseFuture`

You can create your own ResponseFuture for a variety of reasons. This can be used on another future's `join` or `replace` callback for some nice chaining.

Here is an example of a response future that does an expensive operation in another thread.

```
return ResponseFuture<UIImage>() { future in
    // This is an example of how a future is executed and fulfilled.
    DispatchQueue.global(qos: .background).async {
        // let's make an expensive operation on a background thread.
        // The success, updated and error callbacks will be synced on the main thread
        // So no need to sync back to the main thread.

        do {
            // Do an expensive operation here ....
            let resizedImage = try image.resize(ratio: 16/9)

            future.succeed(with: resizedImage)
        } catch {
            future.fail(with: error)
        }
    }
}
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
dispatcher.dataFuture() {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
    var request = URLRequest(url: url, method: .post)
    try request.setJSONBody(post)
    return request
}.error { error in
    // Any error thrown while creating the request will trigger this callback.
}.send()
```

## Decoding

### Unwrapping `Data`

This will unwrap the data object for you or throw a `ResponseError.unexpectedEmptyResponse` if it not there. This is convenient so that you don't have to deal with those pesky optionals. 

```swift
dispatcher.dataFuture(from: request).success { response in
    let data = try response.unwrapData()

    // do something with data.
    print(data)
}.error { error in 
    // Triggered when the data object is not there.
}.send()
```

### Decode `String`

```swift
dispatcher.dataFuture(from: request).success { response in
    let string = try response.decodeString(encoding: .utf8)

    // do something with string.
    print(string)
}.error { error in
    // Triggered when decoding fails.
}.send()
```

### Decode `Decodable`

```swift
dispatcher.dataFuture(from: request).success { response in
    let posts = try response.decode([Post].self)

    // do something with the decodable object.
    print(posts)
}.error { error in
    // Triggered when decoding fails.
}.send()
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

## Memory Management

The `ResponseFuture` may have 3 types of strong references: 
1. The system may have a strong reference to the `ResponseFuture` after `send()` is called. This reference is temporary and will be deallocated once the system returns a response. This will never create a circular reference but as the future is held on by the system, it will not be released until **AFTER** a response is received or an error is triggered.
2. Any callback that references `self` has a strong reference to `self` unless `[weak self]` is explicitly specified.
3. The developer's own strong reference to the `ResponseFuture`.

### Strong callbacks

When **ONLY**  `1` and `2` applies to your case, a temporary circular reference is created until the future is resolved. You may wish to use `[weak self]` in this case but it is not necessary.

```swift
dispatcher.dataFuture(from: request).then({ response -> [Post] in
    // [weak self] not needed as `self` is not called
    return try response.decode([Post].self)
}).success({ posts in
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

You will have crashes if you force unwrap anything in your callbacks (i.e. using a `!`). We suggest you **ALWAYS** avoid force unwrapping anything in your callbacks. 

Always unwrap your objects before using them. This includes any `IBOutlet`s that the system generates. Use a guard, Use an assert. Use anything but a `!`.

## Mock Dispatcher

Testing network calls is always a pain. That's why we included the `MockURLRequestDispatcher`. It allows you to simulate network responses without actually making network calls.

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
        return try Response.makeMockResponse(with: request, statusCode: .notFound)
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
