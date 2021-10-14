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
    
    private let dispatcher = MockURLRequestDispatcher(delay: 0.5, callback: { request in
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
    
    private let instantDispatcher = MockURLRequestDispatcher(delay: 0, callback: { request in
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

    func testFutureResponse() {
        // When
        var calledCompletion = false
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        let progressExpectation = self.expectation(description: "Progress triggered")
        progressExpectation.expectedFulfillmentCount = 4
        
        // Then
        
        dispatcher.dataFuture() {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }.then { response -> Post in
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
        }.replace(EnrichedPost.self) { [weak self] post in
            // Perform some operation operation that itself requires a future
            // such as something heavy like markdown parsing.
            XCTAssertFalse(calledCompletion)
            return self?.enrich(post: post)
        }.seriesJoin(User.self) { [weak self] enrichedPost in
            // Joins a future with another one
            XCTAssertFalse(calledCompletion)
            return self?.fetchUser(forId: enrichedPost.post.userId)
        }.response { enrichedPost, user in
            // The final response callback includes all the transformations and
            // Joins we had previously performed.
            XCTAssertFalse(calledCompletion)
            successExpectation.fulfill()
        }.error { error in
            XCTFail("Should not trigger the failure")
        }.updated { task in
            progressExpectation.fulfill()
        }.completion {
            calledCompletion = true
            completionExpectation.fulfill()
        }.send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testNonFailingFutureResponse() {
        // When
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        let progressExpectation = self.expectation(description: "Progress triggered")
        progressExpectation.expectedFulfillmentCount = 2
        
        // Then
        
        instantDispatcher.dataFuture() {
            let url = URL(string: "https://jsonplaceholder.typicode.com/unknown/1")!
            return URLRequest(url: url, method: .get)
        }.then { response -> Post in
            return try response.decode(Post.self)
        }.safeResult().success { response in
            switch response {
            case .success:
                XCTFail()
            case .failure:
                break
            }
            
            successExpectation.fulfill()
        }.error { error in
            XCTFail(error.localizedDescription)
        }.updated { task in
            progressExpectation.fulfill()
        }.completion {
            completionExpectation.fulfill()
        }.send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testTaskCallback() {
        // Expectations
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        let progressExpectation = self.expectation(description: "Progress triggered")
        progressExpectation.expectedFulfillmentCount = 2
        
        // Then

        instantDispatcher.dataFuture() {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
        }.then { response -> Post in
            return try response.decode(Post.self)
        }.safeResult().success { response in
            switch response {
            case .success:
                break
            case .failure:
                XCTFail()
            }
            
            successExpectation.fulfill()
        }.error { error in
            XCTFail(error.localizedDescription)
        }.updated { task in
            progressExpectation.fulfill()
        }.completion {
            completionExpectation.fulfill()
        }.send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    private func enrich(post: Post) -> ResponseFuture<EnrichedPost> {
        return ResponseFuture<EnrichedPost>() { future in
            future.succeed(with: (post, nil))
        }
    }
    
    private func fetchUser(forId id: Int) -> ResponseFuture<User> {
        return instantDispatcher.dataFuture() {
            let url = URL(string: "https://jsonplaceholder.typicode.com/users/1")!
            return URLRequest(url: url, method: .get)
        }.map(User.self) { response in
            return try response.decode(User.self)
        }
    }
    
    func testFuture() {
        // Expectations
        let successExpectation = self.expectation(description: "Success response triggered")
        let progressExpectation = self.expectation(description: "Progress triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        progressExpectation.expectedFulfillmentCount = 2
        
        // When
        instantDispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
            return URLRequest(url: url, method: .get)
        }).response({ posts in
            // Then
            successExpectation.fulfill()
        }).updated({ task in
            progressExpectation.fulfill()
        }).error({ error in
            XCTFail(error.localizedDescription)
        }).completion({
            completionExpectation.fulfill()
        }).send()
        
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
        
        weak var weakFuture: ResponseFuture<(EnrichedPost, User)>? = dispatcher.dataFuture() {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
            return URLRequest(url: url, method: .get)
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
        weakFuture?.send()
        XCTAssertNil(weakFuture)
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFutureIsCancelledWhenNilIsReturnedInSeriesJoin() {
        let cancellationExpectation = self.expectation(description: "Cancellation response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        let urlRequest = URLRequest(url: url, method: .get)
        
        instantDispatcher.dataFuture(from: urlRequest)
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
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        let urlRequest = URLRequest(url: url, method: .get)
        
        instantDispatcher.dataFuture(from: urlRequest)
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
    
    func testFutureWithParallelJoins() {
        // Expectations
        let count = 1000
        let successExpectation = self.expectation(description: "Success response triggered")
        let progressExpectation = self.expectation(description: "Progress triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        progressExpectation.expectedFulfillmentCount = count * 2
        
        // Given
        
        var future = ResponseFuture<[Post]> { future in
            future.succeed(with: [])
        }
        
        weak var weakFuture: ResponseFuture<[Post]>? = future
        
        for id in 1...count {
            future = future
                .parallelJoin(Post.self) {
                    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!
                    let urlRequest = URLRequest(url: url, method: .get)
                    
                    return self.instantDispatcher.dataFuture(from: urlRequest)
                        .then { response in
                            return try response.decode(Post.self)
                        }
                }.map([Post].self) { posts, addedPost in
                    var posts = posts
                    posts.append(addedPost)
                    return posts
                }
        }
        
        // When
        
        future.updated { task in
            progressExpectation.fulfill()
        }
        .success { posts in
            successExpectation.fulfill()
            XCTAssertEqual(count, posts.count)
            
            for id in 1...count {
                XCTAssertEqual(posts[id - 1].id, id)
            }
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
        
        XCTAssertNotNil(weakFuture)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(weakFuture)
        }
    }
}
