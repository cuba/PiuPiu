//
//  ResponseFutureTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-04-13.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import PiuPiu
@testable import Example

class ResponseFutureTests: XCTestCase {
    typealias EnrichedPost = (post: Post, markdown: NSAttributedString?)
    
    private let postDispatcher = MockURLRequestDispatcher(delay: 0, callback: { request in
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        return try Response.makeMockJSONResponse(with: request, encodable: post, statusCode: .ok)
    })
    
    private let postsDispatcher = MockURLRequestDispatcher(delay: 0, callback: { request in
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        return try Response.makeMockJSONResponse(with: request, encodable: [post], statusCode: .ok)
    })
    
    private let userDispatcher = MockURLRequestDispatcher(delay: 0, callback: { request in
        let user = User(id: 1, name: "Jim Halpert")
        return try Response.makeMockJSONResponse(with: request, encodable: user, statusCode: .ok)
    })
    
    private let serverProvider = MockServerProvider()

    func testFutureResponse() {
        // When
        var calledCompletion = false
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        // Then
        
        postDispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).then({ response -> Post in
            // Handles any responses and transforms them to another type
            // This includes negative responses such as 4xx and 5xx
            
            // The error object is available if we get an
            // undesirable status code such as a 4xx or 5xx
            if let error = response.error {
                // Throwing an error in any callback will trigger the `error` callback.
                // This allows us to pool all our errors in one place.
                throw error
            }
            
            XCTAssertFalse(calledCompletion)
            return try response.decode(Post.self)
        }).replace({ post -> ResponseFuture<EnrichedPost> in
            // Perform some operation operation that itself requires a future
            // such as something heavy like markdown parsing.
            XCTAssertFalse(calledCompletion)
            return self.enrich(post: post)
        }).join({ enrichedPost -> ResponseFuture<User> in
            // Joins a future with another one
            XCTAssertFalse(calledCompletion)
            return self.fetchUser(forId: enrichedPost.post.userId)
        }).response({ enrichedPost, user in
            // The final response callback includes all the transformations and
            // Joins we had previously performed.
            XCTAssertFalse(calledCompletion)
            successExpectation.fulfill()
        }).error({ error in
            XCTFail("Should not trigger the failure")
        }).completion({
            calledCompletion = true
            completionExpectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    private func enrich(post: Post) -> ResponseFuture<EnrichedPost> {
        return ResponseFuture<EnrichedPost>() { future in
            future.succeed(with: (post, nil))
        }
    }
    
    private func fetchUser(forId id: Int) -> ResponseFuture<User> {
        return userDispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/users/1")!
            return URLRequest(url: url, method: .get)
        }).then({ response -> User in
            return try response.decode(User.self)
        })
    }
    
    func testFuture() {
        // Expectations
        let expectation = self.expectation(description: "Success response triggered")
        
        // When
        postsDispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
            return URLRequest(url: url, method: .get)
        }).response({ posts in
            // Then
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFutureDealocationWhenCallbacksAreCalled() {
        weak var weakFuture: ResponseFuture<(EnrichedPost, User)>? = postDispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).then({ response -> Post in
            return try response.decode(Post.self)
        }).replace({ post -> ResponseFuture<EnrichedPost> in
            return self.enrich(post: post)
        }).join({ enrichedPost -> ResponseFuture<User> in
            // Joins a future with another one
            return self.fetchUser(forId: enrichedPost.post.userId)
        }).success({ response in
            // Do nothing
        }).error({ error in
            // Do nothing
        }).completion({
            // Do nothing
        }).cancellation {
            // Do nothing
        }
        
        // Our object is already nil because we have not established a strong reference to it.
        // The `send` method will do nothing. No callback will be triggered.
        //weakFuture?.send()
        XCTAssertNil(weakFuture)
    }
    
    func testFutureIsCancelledWhenNilIsReturnedInThen() {
        let expectation = self.expectation(description: "Cancellation response triggered")
        
        postDispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).then({ response -> Post? in
            return nil
        }).cancellation({
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFutureIsCancelledWhenNilIsReturnedInSeriesJoin() {
        let expectation = self.expectation(description: "Cancellation response triggered")
        
        postDispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).join({ response -> ResponseFuture<Response<Data>>? in
            return nil
        }).cancellation({
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFutureIsCancelledWhenNilIsReturnedInParallelJoin() {
        let expectation = self.expectation(description: "Cancellation response triggered")
        
        postDispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).join({ () -> ResponseFuture<Response<Data>>? in
            return nil
        }).cancellation({
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFutureIsCancelledWhenNilIsReturnedInReplace() {
        let expectation = self.expectation(description: "Cancellation response triggered")
        
        postDispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }).replace({ response -> ResponseFuture<Response<Data>>? in
            return nil
        }).cancellation({
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}
