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

    func testFutureResponse() {
        // Given
        
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        let request = BasicRequest(method: .get, path: "/posts/1")
        
        do {
            try dispatcher.setMockData(post)
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        // When
        
        var calledCompletion = false
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        // Then
        
        dispatcher.future(from: request).then({ response -> Post in
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
            return self.fetchUser(forId: post.userId)
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
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    private func enrich(post: Post) -> ResponseFuture<EnrichedPost> {
        return ResponseFuture<EnrichedPost>() { future in
            future.succeed(with: (post, nil))
        }
    }
    
    private func fetchUser(forId id: Int) -> ResponseFuture<User> {
        let request = BasicRequest(method: .get, path: "/users/\(id)")
        let user = User(id: id, name: "Jim Halpert")
        let dispatcher = try! MockDispatcher.makeDispatcher(with: user, status: .ok)
        
        do {
            try dispatcher.setMockData(user)
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        return dispatcher.future(from: request).then({ response -> User in
            return try response.decode(User.self)
        })
    }
    
    func testFuture() {
        let expectation = self.expectation(description: "Success response triggered")
        let request = BasicRequest(method: .get, path: "/posts")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let dispatcher = try! MockDispatcher.makeDispatcher(with: [post], status: .ok)
        
        do {
            try dispatcher.setMockData([post])
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        let response = try! dispatcher.response(from: request)
        
        makeFuture(from: response).response({ posts in
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    private func makeFuture(from response: Response<Data?>) -> ResponseFuture<[Post]> {
        // Promises can wrap callbacks so they are executed when start()
        // is triggered.
        return ResponseFuture<[Post]>(action: { future in
            // This is an example of how a future is executed and
            // fulfilled.
            
            // You should always syncronize
            DispatchQueue.global(qos: .userInitiated).async {
                // lets make an expensive operation on a background thread.
                // The below is just an example of how you can parse on a seperate thread.
                
                do {
                    // Do an expensive operation here ....
                    let posts = try response.decode([Post].self)
                    
                    DispatchQueue.main.async {
                        // We should syncronyze the result back to the main thread.
                        future.succeed(with: posts)
                    }
                } catch {
                    // We can handle any errors as well.
                    DispatchQueue.main.async {
                        // We should syncronize the error to the main thread.
                        future.fail(with: error)
                    }
                }
            }
        })
    }
}
