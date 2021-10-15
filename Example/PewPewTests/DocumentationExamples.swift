//
//  DocumentationExamples.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-02-20.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import Example
@testable import PiuPiu

class DocumentationExamples: XCTestCase {
    typealias EnrichedPost = (post: Post, markdown: NSAttributedString?)
    
    /// This is not a real decoder. It pretends to decode.
    class Parser {
        static func parse(markdown: String) throws -> NSAttributedString? {
            if #available(iOS 15, *) {
                return NSAttributedString(string: markdown)
            } else {
                return nil
            }
        }
    }
    
    private var strongFuture: ResponseFuture<Post>?
    private var post: Post?
    private var user: User?
    
    private let dispatcher = MockURLRequestDispatcher(delay: 0, callback: { request in
        if let id = request.integerValue(atIndex: 1, matching: [.constant("posts"), .wildcard(type: .integer)]) {
            let post = Post(id: id, userId: 123, title: "Some post", body: "Lorem ipsum ...")
            return try Response.makeMockJSONResponse(with: request, encodable: post, statusCode: .ok)
        } else if let id = request.integerValue(atIndex: 1, matching: [.constant("users"), .wildcard(type: .integer)]) {
            let user = User(id: id, name: "Jim Halpert")
            return try Response.makeMockJSONResponse(with: request, encodable: user, statusCode: .ok)
        } else if request.pathMatches(pattern: [.constant("posts")]) {
            let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
            return try Response.makeMockJSONResponse(with: request, encodable: [post], statusCode: .ok)
        } else if request.pathMatches(pattern: [.constant("users")]) {
            let user = User(id: 123, name: "Jim Halpert")
            return try Response.makeMockJSONResponse(with: request, encodable: [user], statusCode: .ok)
        } else {
            return Response.makeMockResponse(with: request, statusCode: .notFound)
        }
    })
    
    func testSimpleRequest() {
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
    }
    
    func testComplexRequest() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        let request = URLRequest(url: url, method: .get)
        
        dispatcher.dataFuture(from: request)
            .then(HTTPResponse<Data?>.self) { response -> HTTPResponse<Data?> in
                // In this callback we handle common HTTP errors
                
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
                }
                
                // Everything is good, so we just return our HTTP response.
                return httpResponse
            }
            .then(HTTPResponse<Post>.self, on: DispatchQueue.global(qos: .background)) { httpResponse -> HTTPResponse<Post> in
                // Here we decode the http response into an object using `Decodable`
                // We use the `background` thread because decoding can be somewhat intensive.
                
                // WARNING: Do not use `self` here as
                // this `callback` is being invoked on a `background` queue
                
                // PiuPiu has a convenience method to decode responses containing `Decodable` objects
                // We use `decodeResponse` instead of just `decode`. This will convert
                // HTTPResponse<Data?> into HTTPResponse<Post>
                return try httpResponse.decoded(Post.self)
            }
            .updated { task in
                // Provides tasks so you can perform things like progress updates
            }
            .success { response in
                // Here we handle our success as long as nothing was thrown along the way
                // This method is always invoked on the main queue.
                
                // At this point, we know all of our errors are handled
                // and our object is deserialized so we can use it simply like this:
                self.post = response.data

                // now we can present our post
                // ...
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
    }

    func testGetPostExample() {
        getPost(id: 1)
            .success { response in
                // Here we handle our success as long as nothing was thrown along the way
                // This method is always invoked on the main queue.
                
                // At this point, we know all of our errors are handled
                // and our object is deserialized so we can use it simply like this:
                self.post = response.data

                // now we can present our post
                // ...
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
    }
    
    func testGetPostExtensionsExample() {
        getUser(id: 1)
            .success { response in
                // Here we handle our success as long as nothing was thrown along the way
                // This method is always invoked on the main queue.
                
                // At this point, we know all of our errors are handled
                // and our object is deserialized so we can use it simply like this:
                self.user = response.data

                // now we can present our user
                // ...
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
    }
    
    /// This method returns an HTTP resposne containing a decoded `Post` object
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
    
    /// This method returns an HTTP response containing a decoded `User` object
    func getUser(id: Int) -> ResponseFuture<HTTPResponse<User>> {
        let url = URL(string: "https://jsonplaceholder.typicode.com/users/1")!
        let request = URLRequest(url: url, method: .get)
        
        return dispatcher.dataFuture(from: request)
            .validHTTPResponse
            .decoded(User.self)
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
    
    func testWrapEncodingInAFutureExample() {
        // Given
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        // When
        dispatcher
            .dataFuture {
                let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
                var request = URLRequest(url: url, method: .post)
                try request.setJSONBody(post)
                return request
            }
            .error { error in
                // Any error thrown while creating the request will trigger this callback.
            }
            .send()
    }
    
    func testFullResponseFutureExample() {
        dispatcher
            .dataFuture {
                let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
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
            }
            .send()
    }
    
    func testWeakCallbacks() {
        // Expectations
        let expectation = self.expectation(description: "Success response triggered")
        
        dispatcher
            .dataFuture {
                let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
                return URLRequest(url: url, method: .get)
            }
            .then { response -> Post in
                return try response.decode(Post.self)
            }
            .success { [weak self] post in
                // [weak self] needed as `self` is called
                self?.show(post)
            }
            .completion {
                // [weak self] needed as `self` is called
                // You can use an optional self directly.
                expectation.fulfill()
            }
            .send()
        
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testWeakCallbacksStrongReference() {
        // Expectations
        let expectation = self.expectation(description: "Success response triggered")
        
        self.strongFuture = dispatcher
            .dataFuture {
                let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
                return URLRequest(url: url, method: .get)
            }
            .then { response -> Post in
                // [weak self] not needed as `self` is not called
                return try response.decode(Post.self)
            }
            .success { [weak self] post in
                // [weak self] needed as `self` is called
                self?.show(post)
            }
            .completion { [weak self] in
                // [weak self] needed as `self` is called
                self?.strongFuture = nil
                expectation.fulfill()
            }
        
        // Perform other logic, add delay, do whatever you would do that forced you
        // to store a reference to this future in the first place
        
        self.strongFuture?.send()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCustomFuture() {
        // Expectations
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        let image = UIImage()
        
        resize(image: image)
            .success { resizedImage in
                // Handle success
            }
            .error { error in
                // Handle error
            }
            .completion {
                // Handle completion
                completionExpectation.fulfill()
            }
            .start()
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testSuccessCallbackExample() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        let request = URLRequest(url: url, method: .get)
        
        dispatcher.dataFuture(from: request)
            .success { response in
                // Triggered when a response is received and all callbacks succeed.
            }
            .send()
    }
    
    func testErrorCallbackExample() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        let request = URLRequest(url: url, method: .get)
        
        dispatcher.dataFuture(from: request)
            .error { error in
                // Any errors thrown in any other callback will be triggered here.
                // Think of this as the `catch` on a `do` block.
            }
            .send()
    }
    
    func testCompletionCallbackExample() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        let request = URLRequest(url: url, method: .get)
        
        dispatcher.dataFuture(from: request)
            .completion {
                // The completion callback guaranteed to be called once
                // for every time the `send` or `start` method is triggered on the callback.
            }
            .send()
    }
    
    func testThenCallbackExample() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        let request = URLRequest(url: url, method: .get)
        
        dispatcher.dataFuture(from: request)
            .then([Post].self, on: .main) { response in
                // This callback transforms the future from one form to another
                // (i.e. it changes the return object)

                // Any errors thrown will be handled by the `error` callback
                return try response.decode([Post].self)
            }
            .send()
    }
    
    func testReplaceCallbackExample() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        let request = URLRequest(url: url, method: .get)
        
        dispatcher.dataFuture(from: request)
            .replace(EnrichedPost.self) { [weak self] response in
                // Perform some operation operation that itself requires a future
                // such as something heavy like markdown parsing.
                let post = try response.decode(Post.self)
                
                // In this case we're parsing markdown and enriching the post.
                return self?.enrich(post: post)
            }
            .success { enrichedPost in
                // The final response callback has the enriched post.
            }
            .send()
    }
    
    func testResultCallbackExample() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        let request = URLRequest(url: url, method: .get)
        
        dispatcher.dataFuture(from: request)
            .result { result in
                // This will put both success and error object in a Result<Success, Error> callback
                // This is useful when you need to treat success and error in a similar fashion.
                
                // Doing this will not prevent this future and all other joined futures from failing.
                // For that you should use `safeResult()` or `safeParallelJoin` and `safeSeriesJoin`
            }
            .send()
    }
    
    func testSeriesJoinCallbackExample() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        let request = URLRequest(url: url, method: .get)
        
        dispatcher.dataFuture(from: request)
            .decoded(Post.self)
            .seriesJoin(Response<User>.self) { [weak self] result in
                guard let self = self else {
                    // We used [weak self] because our dispatcher is referenced on self.
                    // Returning nil will cancel execution of this promise
                    // and triger the `cancellation` and `completion` callbacks.
                    // Do this check to prevent memory leaks.
                    return nil
                }
                // Joins a future with another one returning both results.
                // Since this callback is non-escaping, you don't have to use [weak self]
                let url = URL(string: "https://jsonplaceholder.typicode.com/users/\(result.data.userId)")!
                let request = URLRequest(url: url, method: .get)
                
                return self.dispatcher.dataFuture(from: request)
                    .decoded(User.self)
            }
            .success { (post: Response<Post>, user: Response<User>) in
                // The final response callback includes both responses
                // Here is what happened in order:
                // * `dispatcher.dataFuture(from: request)` method gave us a `Result<Data?>` future
                // * `decoded([Post].self)` method transformed the future to `Result<[Post]>`
                // * `seriesJoin` gave us a second result as a touple which transformed the future to (Response<Post>, Response<User>)
            }
            .send()
    }
    
    func testParallelJoinCallbackExample() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        let request = URLRequest(url: url, method: .get)
        
        dispatcher.dataFuture(from: request)
            .makeHTTPResponse()
            .decoded([Post].self)
            .safeResult()
            .parallelJoin(Result<HTTPResponse<[User]>, Error>.self) {
                // Joins a future with another one returning both results.
                // Since this callback is non-escaping, you don't have to use [weak self]
                let url = URL(string: "https://jsonplaceholder.typicode.com/users")!
                let request = URLRequest(url: url, method: .get)
                
                return self.dispatcher.dataFuture(from: request)
                    .makeHTTPResponse()
                    .decoded([User].self)
                    .safeResult()
            }
            .success { (posts: Result<HTTPResponse<[Post]>, Error>, users: Result<HTTPResponse<[User]>, Error>) in
                // The final response callback includes both results.
                // Here is what happened in order:
                // * `dispatcher.dataFuture(from: request)` method gave us a `Result<Data?>` future
                // * `makeHTTPResponse()` method transfomed the future to `HTTPResponse<Data?>`
                // * `decoded([Post].self)` method transformed the future to `HTTPResponse<[Post]>`
                // * `safeResult` method transformed the future to `Result<HTTPResponse<[Post]>`
                // * `parallelJoin` gave us a second result with its own changes which transformed the future to (Result<HTTPResponse<[Post]>, Error>, Result<HTTPResponse<[User]>, Error>)
                
                // If any futures fail, this callbakc will not be called. To prevent that, we need to use a `safeResult()`
            }
            .send()
    }
    
    func testSafeParallelJoinCallbackExample() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        let request = URLRequest(url: url, method: .get)
        
        dispatcher.dataFuture(from: request)
            .decoded([Post].self)
            .safeParallelJoin(Response<[User]>.self) {
                // Joins a future with another one returning both results.
                // Since this callback is non-escaping, you don't have to use [weak self]
                let url = URL(string: "https://jsonplaceholder.typicode.com/users")!
                let request = URLRequest(url: url, method: .get)
                
                return self.dispatcher.dataFuture(from: request)
                    .decoded([User].self)
            }
            .success { (posts: Response<[Post]>, users: Result<Response<[User]>, Error>) in
                // The final response callback includes both results.
                // Here is what happened in order:
                // * `dispatcher.dataFuture(from: request)` method gave us a `Result<Data?>` future
                // * `decoded([Post].self)` method transformed the future to `Response<[Post]>`
                // * `safeParallelJoin` gave us a second result with its own changes which transformed the future to (Response<[Post]>, Result<Response<[User]>, Error>).
                
                // Notice we are no longer calling `safeResponse()` and yet we still get a `Result<Response<[User]>, Error>` for the joined future. This is because safeResponse() is done for us via the `safeParallelJoin`
                
                // Also notice that we don't call `safeResult()` before doing the join. This means that the first response is "unsafe" and will cause everythign to fail if it has an error. But this might be exactly what we want depending on our business rules.
            }
            .send()
    }
    
    func testSafeResultMethodExample() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        let request = URLRequest(url: url, method: .get)
        
        dispatcher.dataFuture(from: request)
            .decoded([Post].self)
            .safeResult()
            .success { (posts: Result<Response<[Post]>, Error>) in
                // Here is what happened in order:
                // * `dispatcher.dataFuture(from: request)` method gave us a `Result<Data?>` future
                // * `decoded([Post].self)` method transformed the future to `HTTPResponse<[Post]>`
                // * `safeResult()` method transfomed the future to `Result<HTTPResponse<Data?>, Error>`
                
                // Unlike the parallel call example above, the error callback will never be triggered as we do safeResult right before the success
            }
            .send()
    }
    
    func testDecodedMethodExample() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        let request = URLRequest(url: url, method: .get)
        
        dispatcher.dataFuture(from: request)
            .makeHTTPResponse()
            .decoded([Post].self)
            .success { (posts: HTTPResponse<[Post]>) in
                // Here is what happened in order:
                // * `dispatcher.dataFuture(from: request)` method gave us a `Result<Data?>` future
                // * `makeHTTPResponse()` method transfomed the future to `HTTPResponse<Data?>`
                // * `decoded([Post].self)` method transformed the future to `HTTPResponse<[Post]>`
            }
            .send()
    }
    
    private func enrich(post: Post) -> ResponseFuture<EnrichedPost> {
        return ResponseFuture<EnrichedPost>() { future in
            DispatchQueue.global(qos: .background).async {
                do {
                    let enrichedPost = try Parser.parse(markdown: post.body)
                    future.succeed(with: (post, enrichedPost))
                } catch {
                    future.fail(with: error)
                }
            }
        }
    }
    
    private func resize(image: UIImage) -> ResponseFuture<UIImage> {
        return ResponseFuture<UIImage> { future in
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
                    future.succeed(with: resizedImage)
                } catch {
                    future.fail(with: error)
                }
            }
        }
    }
    
    
    
    private func show(_ post: Post) {
        print(post)
    }
}

extension UIImage {
    func resize(ratio: CGFloat) throws -> UIImage {
        return self
    }
}

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
