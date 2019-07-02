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

class DocumentationExamples: XCTestCase, ServerProvider {
    
    struct ServerErrorDetails: Codable {
    }
    
    var baseURL: URL? {
        return URL(string: "https://jsonplaceholder.typicode.com")
    }
    
    private var strongFuture: ResponseFuture<[Post]>?
    private weak var weakFuture: ResponseFuture<Response<Data?>>?
    
    func testSimpleRequest() {
        let request = BasicRequest(method: .get, path: "/posts")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let dispatcher = try! MockDispatcher.makeDispatcher(with: [post], status: .ok)
        
        dispatcher.future(from: request).response({ response in
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
    }

    func testGetPostsExample() {
        let responseExpectation = self.expectation(description: "Response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        let errorExpectation = self.expectation(description: "Error triggered")
        
        responseExpectation.expectedFulfillmentCount = 1
        completionExpectation.expectedFulfillmentCount = 1
        errorExpectation.isInverted = true
        
        getPosts().response({ posts in
            // Handle the success which will give your posts.
            responseExpectation.fulfill()
        }).error({ error in
            // Triggers whenever an error is thrown.
            // This includes deserialization errors, unwraping failures, and anything else that is thrown
            // in a any other throwable callback.
            errorExpectation.fulfill()
        }).completion({
            // Always triggered at the very end to inform you this future has been satisfied.
            completionExpectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    private func getPosts() -> ResponseFuture<[Post]> {
        let request = BasicRequest(method: .get, path: "/posts")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let dispatcher = try! MockDispatcher.makeDispatcher(with: [post], status: .ok)
        
        // We create a future and tell it to transform the response using the
        // `then` callback.
        return dispatcher.future(from: request).then({ response -> [Post] in
            if let error = response.error {
                // The error is available when a non-2xx response comes in
                // Such as a 4xx or 5xx
                // You may also parse a custom error object here.
                throw error
            } else {
                // Return the decoded object. If an error is thrown while decoding,
                // It will be caught in the `error` callback.
                return try response.decode([Post].self)
            }
        })
    }
    
    func testWrapEncodingInAFuture() {
        // Given
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let dispatcher = try! MockDispatcher.makeDispatcher(with: [post], status: .ok)
        
        // Then
        let expectation = self.expectation(description: "Success response triggered")
        
        // When
        dispatcher.future(from: {
            var request = BasicRequest(method: .post, path: "/posts")
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
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let dispatcher = try! MockDispatcher.makeDispatcher(with: post, status: .ok)
        
        dispatcher.future(from: {
            var request = BasicRequest(method: .post, path: "/posts")
            try request.setJSONBody(post)
            return request
        }).then({ response -> Post in
            // Handles any responses and transforms them to another type
            // This includes negative responses such as 400s and 500s
            
            if let error = response.error {
                // We throw the error so we can handle it in the `error` callback.
                // We can also handle the error response in a more custom way if we chose.
                throw error
            } else {
                // if we have no error, we just return the decoded object
                // If anything is thrown, it will be caught in the `error` callback.
                return try response.decode(Post.self)
            }
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
        let expectation = self.expectation(description: "Success response triggered")
        
        let request = BasicRequest(method: .get, path: "/posts")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let dispatcher = try! MockDispatcher.makeDispatcher(with: [post], status: .ok)
        dispatcher.delay = 2
        
        dispatcher.future(from: request).then({ response -> [Post] in
            // [weak self] not needed as `self` is not called
            return try response.decode([Post].self)
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
        let expectation = self.expectation(description: "Success response triggered")
        let request = BasicRequest(method: .get, path: "/posts")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let dispatcher = try! MockDispatcher.makeDispatcher(with: [post], status: .ok)
        dispatcher.delay = 2
        
        self.strongFuture = dispatcher.future(from: request).then({ response -> [Post] in
            // [weak self] not needed as `self` is not called
            return try response.decode([Post].self)
        }).response({ [weak self] post in
            // [weak self] needed as `self` is called
            self?.show(post)
        }).completion({ [weak self] in
            // [weak self] needed as `self` is called
            self?.strongFuture = nil
            expectation.fulfill()
        })
        
        // Perform other logic, add delay, do whatever you would do that forced you
        // to store a reference to this promise in the first place
        
        self.strongFuture?.send()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testWeakCallbacksWeakReferenceDealocated() {
        let expectation = self.expectation(description: "Success response should not be triggered")
        expectation.isInverted = true
        
        let request = BasicRequest(method: .get, path: "/posts")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let dispatcher = try! MockDispatcher.makeDispatcher(with: [post], status: .ok)
        dispatcher.delay = 2
        
        self.weakFuture = dispatcher.future(from: request).completion({
            // [weak self] needed as `self` is not called
            expectation.fulfill()
        })
        
        // Our object is already nil because we have not established a strong reference to it.
        // The `send` method will do nothing. No callback will be triggered.
        
        XCTAssertNil(self.weakFuture)
        self.weakFuture?.send()
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    private func show(_ posts: [Post]) {
        print(posts)
    }
}
