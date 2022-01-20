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

    private lazy var fileDispatcher: URLRequestDispatcher = {
        return URLRequestDispatcher(responseAdapter: MockHTTPResponseAdapter.success)
    }()

    func testFutureResponse() {
        // When
        var progressCount = 0
        var calledCompletion = false
        var calledSuccess = false
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        // Then
        
        fileDispatcher
            .dataFuture {
                return URLRequest(url: MockJSON.post.url, method: .get)
            }
            .then(Post.self) { response -> Post in
                response.debug()
                // Attempt to get a http response
                let httpResponse = try response.makeHTTPResponse()
                
                // Check if we have any http error
                if let error = httpResponse.httpError {
                    // Throwing an error in any callback will trigger the `error` callback.
                    // This allows us to pool all failures in that callback if we want to
                    throw error
                }
                
                XCTAssertFalse(calledCompletion)
                return try response.decode(Post.self)
            }
            .replace(EnrichedPost.self) { [weak self] post in
                // Perform some operation operation that itself requires a future
                // such as something heavy like markdown parsing.
                XCTAssertFalse(calledCompletion)
                return self?.enrich(post: post)
            }
            .seriesJoin(User.self) { [weak self] enrichedPost in
                // Joins a future with another one
                XCTAssertFalse(calledCompletion)
                return self?.fetchUser(forId: enrichedPost.post.userId)
            }
            .success { enrichedPost, user in
                // The final response callback includes all the transformations and
                // Joins we had previously performed.
                calledSuccess = true
                XCTAssertFalse(calledCompletion)
            }
            .error { error in
                // Handles any errors throw in any callbacks
                XCTFail("Should not trigger the failure")
            }
            .updated { task in
                // Provides tasks so you can perform things like progress updates
                XCTAssertFalse(calledCompletion)
                progressCount += 1
            }
            .completion {
                // At the end of all the callbacks, this is triggered once. Error or no error.
                calledCompletion = true
                completionExpectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: { _ in
            XCTAssert(calledSuccess)
            XCTAssertEqual(progressCount, 6)
        })
    }
    
    func testNonFailingFutureResponse() {
        // When
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        var progressCount = 0
        var calledSuccess = false
        
        // Then
        
        fileDispatcher
            .dataFuture {
                return URLRequest(url: MockJSON.post.url, method: .get)
            }
            .then { response -> Post in
                return try response.decode(Post.self)
            }
            .safeResult().success { response in
                switch response {
                case .success:
                    XCTFail()
                case .failure:
                    break
                }
            }
            .success { _ in
                calledSuccess = true
                successExpectation.fulfill()
            }
            .error { error in
                XCTFail(error.localizedDescription)
            }
            .updated { task in
                progressCount += 1
            }
            .completion {
                completionExpectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: { _ in
            XCTAssert(calledSuccess)
            XCTAssertEqual(progressCount, 3)
        })
    }
    
    func testTaskCallback() {
        // Expectations
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        //let progressExpectation = self.expectation(description: "Progress triggered")
        //progressExpectation.expectedFulfillmentCount = 2
        
        // Then

        fileDispatcher
            .dataFuture {
                return URLRequest(url: MockJSON.post.url, method: .get)
            }
            .then { response -> Post in
                return try response.decode(Post.self)
            }
            .safeResult().success { response in
                switch response {
                case .success:
                    break
                case .failure:
                    XCTFail()
                }
                
                successExpectation.fulfill()
            }
            .error { error in
                XCTFail(error.localizedDescription)
            }
            .updated { task in
                //progressExpectation.fulfill()
            }
            .completion {
                completionExpectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    private func enrich(post: Post) -> ResponseFuture<EnrichedPost> {
        return ResponseFuture<EnrichedPost>() { future in
            future.succeed(with: (post, nil))
        }
    }
    
    private func fetchUser(forId id: Int) -> ResponseFuture<User> {
        return fileDispatcher
            .dataFuture {
                return URLRequest(url: MockJSON.user.url, method: .get)
            }
            .map(User.self) { response in
                return try response.decode(User.self)
            }
    }
    
    func testFuture() {
        // Expectations
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        // When
        fileDispatcher
            .dataFuture {
                return URLRequest(url: MockJSON.posts.url, method: .get)
            }
            .success { posts in
                // Then
                successExpectation.fulfill()
            }
            .updated { task in
                //progressExpectation.fulfill()
            }
            .error { error in
                XCTFail(error.localizedDescription)
            }
            .completion {
                completionExpectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFutureDealocationWhenCallbacksAreCalled() {
        // Expectations
        
        let successExpectation = self.expectation(description: "Success response triggered")
        let progressExpectation = self.expectation(description: "Progress triggered")
        let errorExpectation = self.expectation(description: "Error triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        let cancellationExpectation = self.expectation(description: "Cancellation triggered")
        errorExpectation.isInverted = true
        successExpectation.isInverted = true
        progressExpectation.isInverted = true
        completionExpectation.isInverted = true
        cancellationExpectation.isInverted = true
        
        // When
        
        weak var weakFuture: ResponseFuture<(EnrichedPost, User)>? = fileDispatcher
            .dataFuture {
                return URLRequest(url: MockJSON.post.url, method: .get)
            }
            .then { response -> Post in
                return try response.decode(Post.self)
            }
            .replace(EnrichedPost.self) { [weak self] post in
                return self?.enrich(post: post)
            }
            .seriesJoin(User.self) { enrichedPost in
                // Joins a future with another one
                return self.fetchUser(forId: enrichedPost.post.userId)
            }
            .success { response in
                successExpectation.fulfill()
            }
            .error { error in
                errorExpectation.fulfill()
            }
            .completion {
                completionExpectation.fulfill()
            }
            .cancellation {
                cancellationExpectation.fulfill()
            }
        
        // Then
        
        // Our object is already nil because we have not established a strong reference to it.
        // The `send` method will do nothing. No callback will be triggered.
        XCTAssertNil(weakFuture)
        weakFuture?.send()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFutureIsCancelledWhenNilIsReturnedInSeriesJoin() {
        let cancellationExpectation = self.expectation(description: "Cancellation response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        let urlRequest = URLRequest(url: MockJSON.post.url, method: .get)
        
        fileDispatcher.dataFuture(from: urlRequest)
            .seriesJoin(Response<Data>.self) { result in
                return nil
            }
            .success { response in
                XCTFail("Should not be triggered")
            }
            .error { error in
                XCTFail(error.localizedDescription)
            }
            .cancellation {
                cancellationExpectation.fulfill()
            }
            .completion {
                completionExpectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFutureIsCancelledWhenNilIsReturnedInReplace() {
        let cancellationExpectation = self.expectation(description: "Cancellation triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        let urlRequest = URLRequest(url: MockJSON.post.url, method: .get)
        
        fileDispatcher.dataFuture(from: urlRequest)
            .replace(Response<Data>.self) { response in
                return nil
            }
            .success { response in
                XCTFail("Should not be triggered")
            }
            .error { error in
                XCTFail(error.localizedDescription)
            }
            .cancellation {
                cancellationExpectation.fulfill()
            }
            .completion {
                completionExpectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFutureRetentionWithParallelJoins() {
        // Expectations
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        // Given
        
        var future: ResponseFuture<[Post]>? = ResponseFuture<[Post]>
            .init(childFutures: (1...10).map({ id in
                let urlRequest = URLRequest(url: MockJSON.post.url, method: .get)
                
                return self.fileDispatcher.dataFuture(from: urlRequest)
                    .then { response in
                        return try response.decode(Post.self)
                    }
            }))
        
        // We still have a reference to future so weak future is not yet nil
        weak var weakFuture: ResponseFuture<[Post]>? = future
        XCTAssertNotNil(weakFuture)
        
        // We then add a completion handler which will check for retention while the future is still active (non-finalized)
        // and does a send
        weakFuture?
            .completion {
                // The future is retained by the system because each
                // callback retains its future
                // There is a chain of retentions that should be broken
                // when the future is finalized
                XCTAssertNotNil(weakFuture)
                completionExpectation.fulfill()
            }
            .send()
        
        // Then
        // We broke the reference but weak future will still be retained
        // Until all the requests are completed.
        future = nil
        XCTAssertNotNil(weakFuture)
        
        waitForExpectations(timeout: 10) { error in
            future = nil
            XCTAssertNil(error)
            
            // We should have completed all the requests.
            // Now the weak future should be nil
            XCTAssertNil(weakFuture)
        }
    }
    
    func testFutureInitializerWithChildFutures() {
        // Expectations
        let count = 1000
        let successExpectation = self.expectation(description: "Success response triggered")
        //let progressExpectation = self.expectation(description: "Progress triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        //progressExpectation.expectedFulfillmentCount = count * 2
        
        // Given
        let childFutures = (1...count).map { id -> ResponseFuture<Post> in
            makePostFuture(id: id)
        }
        
        ResponseFuture<[Post]>(childFutures: childFutures)
            .updated { task in
                //progressExpectation.fulfill()
            }
            .success { posts in
                XCTAssertEqual(count, posts.count)
                
                for id in 1...count {
                    XCTAssertEqual(posts[id - 1].id, 1)
                }
                
                successExpectation.fulfill()
            }
            .error { error in
                XCTFail(error.localizedDescription)
            }
            .completion {
                completionExpectation.fulfill()
            }
            .cancellation {
                XCTFail("Should not be triggered")
            }
            .send()
        
        // Then
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testFutureInitializerWithArrayLiteral() {
        // Expectations
        let successExpectation = self.expectation(description: "Success response triggered")
        //let progressExpectation = self.expectation(description: "Progress triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        //progressExpectation.expectedFulfillmentCount = 2 * 2
        
        ResponseFuture<[Post]>(arrayLiteral: self.makePostFuture(id: 1), self.makePostFuture(id: 2))
            .updated { task in
                //progressExpectation.fulfill()
            }
            .success { posts in
                XCTAssertEqual(2, posts.count)
                XCTAssertEqual(posts[0].id, 1)
                XCTAssertEqual(posts[1].id, 1)
                successExpectation.fulfill()
            }
            .error { error in
                XCTFail(error.localizedDescription)
            }
            .completion {
                completionExpectation.fulfill()
            }
            .cancellation {
                XCTFail("Should not be triggered")
            }
            .send()
        
        // Then
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    private func makePostFuture(id: Int) -> ResponseFuture<Post> {
        let urlRequest = URLRequest(url: MockJSON.post.url, method: .get)
        
        return self.fileDispatcher.dataFuture(from: urlRequest)
            .then { response in
                return try response.decode(Post.self)
            }
    }
}
