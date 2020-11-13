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
            return try Response.makeMockResponse(with: request, statusCode: .notFound)
        }
    })
    
    func testSimpleRequest() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        let request = URLRequest(url: url, method: .get)
        
        dispatcher.dataFuture(from: request)
            .response { response in
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
            .then() { response -> HTTPResponse<Data?> in
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
            .then(on: DispatchQueue.global(qos: .background)) { httpResponse -> HTTPResponse<Post> in
                // Here we decode the http response into an object using `Decodable`
                // We use the `background` thread because decoding can be somewhat intensive.
                
                // WARNING: Do not use `self` here as
                // this `callback` is being invoked on a `background` queue
                
                // PiuPiu has a convenience method to decode responses containing `Decodable` objects
                // We use `decodeResponse` instead of just `decode`. This will convert
                // HTTPResponse<Data?> into HTTPResponse<Post>
                return try httpResponse.decodedResponse(Post.self)
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
                return try httpResponse.decodedResponse(Post.self)
            }
    }
    
    /// This method returns an HTTP response containing a decoded `User` object
    func getUser(id: Int) -> ResponseFuture<HTTPResponse<User>> {
        let url = URL(string: "https://jsonplaceholder.typicode.com/users/1")!
        let request = URLRequest(url: url, method: .get)
        
        return dispatcher.dataFuture(from: request)
            .validHTTPResponse()
            .decodedResponse(User.self)
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
    
    func testWrapEncodingInAFuture() {
        // Expectations
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        // When
        dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            var request = URLRequest(url: url, method: .post)
            try request.setJSONBody(post)
            return request
        }).error({ error in
            // Any error thrown while creating the request will trigger this callback.
        }).completion({
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFullResponseFutureExample() {
        dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).then({ response -> Post in
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
        }).response({ post in
            // Handles any success responses.
            // In this case the object returned in the `then` method.
        }).error({ error in
            // Handles any errors during the request process,
            // including all request creation errors and anything
            // thrown in the `then` or `success` callbacks.
        }).completion({
            // The completion callback guaranteed to be called once
            // for every time the `start` method is triggered on the callback.
        }).send()
    }
    
    func testWeakCallbacks() {
        // Expectations
        let expectation = self.expectation(description: "Success response triggered")
        
        dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).then({ response -> Post in
            return try response.decode(Post.self)
        }).response({ [weak self] post in
            // [weak self] needed as `self` is called
            self?.show(post)
        }).completion({
            // [weak self] needed as `self` is called
            // You can use an optional self directly.
            expectation.fulfill()
        }).send()
        
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testWeakCallbacksStrongReference() {
        // Expectations
        let expectation = self.expectation(description: "Success response triggered")
        
        self.strongFuture = dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).then({ response -> Post in
            // [weak self] not needed as `self` is not called
            return try response.decode(Post.self)
        }).response({ [weak self] post in
            // [weak self] needed as `self` is called
            self?.show(post)
        }).completion({ [weak self] in
            // [weak self] needed as `self` is called
            self?.strongFuture = nil
            expectation.fulfill()
        })
        
        // Perform other logic, add delay, do whatever you would do that forced you
        // to store a reference to this future in the first place
        
        self.strongFuture?.send()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testWeakCallbacksWeakReferenceDealocated() {
        // Expectations
        let expectation = self.expectation(description: "Success response should not be triggered")
        expectation.isInverted = true
        
        weak var weakFuture: ResponseFuture<Response<Data?>>? = dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).completion({
            // [weak self] needed as `self` is not called
            expectation.fulfill()
        })
        
        // Our object is already nil because we have not established a strong reference to it.
        // The `send` method will do nothing. No callback will be triggered.
        
        XCTAssertNil(weakFuture)
        weakFuture?.send()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSeriesJoin() {
        let expectation = self.expectation(description: "Success response triggered")
        
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
        }.success { post, user in
            // The final response callback includes both results.
            expectation.fulfill()
        }.send()
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testParallelJoin() {
        let expectation = self.expectation(description: "Success response triggered")
        
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
            
            return self.dispatcher.dataFuture(from: request).then({ response -> [User] in
                return try response.decode([User].self)
            })
        }.success { posts, users in
            // The final response callback includes both results.
            expectation.fulfill()
        }.send()
        
        waitForExpectations(timeout: 4, handler: nil)
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
    
    private func resize(image: UIImage) -> ResponseFuture<UIImage> {
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
                    future.succeed(with: resizedImage)
                } catch {
                    future.fail(with: error)
                }
            }
        })
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

extension ResponseFuture where T == Response<Data?> {
    /// This method handles common HTTP errors and returns an HTTP response.
    func validHTTPResponse() -> ResponseFuture<HTTPResponse<Data?>> {
        return then { response -> HTTPResponse<Data?> in
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

extension ResponseFuture where T == HTTPResponse<Data?> {
    /// This method returns an HTTP response containing a decoded object
    func decodedResponse<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) -> ResponseFuture<HTTPResponse<D>> {
        return then(on: DispatchQueue.global(qos: .background)) { httpResponse -> HTTPResponse<D> in
            return try httpResponse.decodedResponse(type, using: decoder)
        }
    }
}
