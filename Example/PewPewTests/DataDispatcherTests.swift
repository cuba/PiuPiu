//
//  DataDispatcherTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-07-07.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import Example
@testable import PiuPiu

class DataDispatcherTests: XCTestCase {
    private lazy var dispatcher: URLRequestDispatcher = {
        return URLRequestDispatcher(responseAdapter: MockHTTPResponseAdapter.success)
    }()
    
    private var strongFuture: ResponseFuture<[Post]>?
    
    func testSimpleRequest() {
        // Expectations
        let completionExpectation = self.expectation(description: "Completion triggered")
        completionExpectation.expectedFulfillmentCount = 1
        
        dispatcher
            .dataFuture {
                let url = MockJSON.post.url
                return URLRequest(url: url, method: .get)
            }
            .success { response in
                // Attempt to get a http response
                let httpResponse = try response.makeHTTPResponse()
                
                // Check if we have any http error
                if let error = httpResponse.httpError {
                    // Throwing an error in any callback will trigger the `error` callback.
                    // This allows us to pool all failures in that callback if we want to
                    throw error
                }
                
                let post = try response.decode(Post.self)
                // Do something with our deserialized object
                // ...
                print(post)
            }
            .error { error in
                // Handles any errors during the request process,
                // including all request creation errors and anything
                // thrown in the `then` or `success` callbacks.
            }
            .completion {
                // The completion callback is guaranteed to be called once
                // for every time the `start` method is triggered on the future.
                completionExpectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGetPostsExample() {
        // Expectations
        let responseExpectation = self.expectation(description: "Response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        responseExpectation.expectedFulfillmentCount = 1
        completionExpectation.expectedFulfillmentCount = 1
        
        // We create a future and tell it to transform the response using the
        // `then` callback.
        dispatcher
            .dataFuture {
                let url = MockJSON.posts.url
                return URLRequest(url: url, method: .get)
            }
            .then([Post].self) { response in
                // Attempt to get a http response
                let httpResponse = try response.makeHTTPResponse()
                
                // Check if we have any http error
                if let error = httpResponse.httpError {
                    // Throwing an error in any callback will trigger the `error` callback.
                    // This allows us to pool all failures in that callback if we want to
                    throw error
                }
                
                // Return the decoded object. If an error is thrown while decoding,
                // It will be caught in the `error` callback.
                return try response.decode([Post].self)
            }
            .success { posts in
                // Handle the success which will give your posts.
                responseExpectation.fulfill()
            }
            .error { error in
                // Triggers whenever an error is thrown.
                // This includes deserialization errors, unwrapping failures, and anything else that is thrown
                // in any other throwable callback.
                XCTFail("Should not be triggered")
            }
            .completion {
                // Always triggered at the very end to inform you this future has been satisfied.
                completionExpectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFullResponseFutureExample() {
        // Expectations
        let completionExpectation = self.expectation(description: "Completion triggered")
        completionExpectation.expectedFulfillmentCount = 1
        
        // When
        dispatcher
            .dataFuture {
                let url = MockJSON.posts.url
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
            .updated{ task in
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
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testWrapEncodingInAFuture() {
        // Expectations
        let completionExpectation = self.expectation(description: "Completion triggered")
        completionExpectation.expectedFulfillmentCount = 1
        
        // Given
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        // When
        dispatcher
            .dataFuture {
                let url = MockJSON.posts.url
                var request = URLRequest(url: url, method: .post)
                try request.setJSONBody(post)
                return request
            }
            .error { error in
                // Any error thrown while creating the request will trigger this callback.
            }
            .completion {
                // Then
                completionExpectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testWeakCallbacks() {
        // TODO: @JS Put this in a class and test that it dealocates it
        // Expectations
        let completionExpectation = self.expectation(description: "Completion triggered")
        completionExpectation.expectedFulfillmentCount = 1
        
        dispatcher
            .dataFuture {
                let url = MockJSON.posts.url
                return URLRequest(url: url, method: .get)
            }
            .then { response -> [Post] in
                // [weak self] not needed as `self` is not called
                return try response.decode([Post].self)
            }
            .success { post in
                // [weak self] needed as `self` is called
            }
            .completion {
                // [weak self] needed as `self` is called
                // You can use an optional self directly.
                completionExpectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testWeakCallbacksStrongReference() {
        // TODO: @JS Put this in a class and test that it dealocates it
        
        // Expectations
        let completionExpectation = self.expectation(description: "Completion triggered")
        completionExpectation.expectedFulfillmentCount = 1
        
        self.strongFuture = dispatcher
            .dataFuture {
                let url = MockJSON.posts.url
                return URLRequest(url: url, method: .get)
            }
            .then { response -> [Post] in
                // [weak self] not needed as `self` is not called
                return try response.decode([Post].self)
            }
            .success { post in
                // [weak self] needed as `self` is called
            }
            .completion{ [weak self] in
                // [weak self] needed as `self` is called
                self?.strongFuture = nil
                completionExpectation.fulfill()
            }
        
        // Perform other logic, add delay, do whatever you would do that forced you
        // to store a reference to this future in the first place
        
        self.strongFuture?.send()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testWeakCallbacksWeakReferenceDealocated() {
        weak var weakFuture: ResponseFuture<Response<Data?>>? = dispatcher
            .dataFuture {
                let url = MockJSON.posts.url
                return URLRequest(url: url, method: .get)
            }
            .completion {
                // [weak self] not needed as `self` is not called
                XCTFail("Should not be triggered")
            }
        
        // Our object is already nil because we have not established a strong reference to it.
        // The `send` method will do nothing. No callback will be triggered.
        weakFuture?.send()
        XCTAssertNil(weakFuture)
    }
}
