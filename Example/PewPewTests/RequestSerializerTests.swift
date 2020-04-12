//
//  RequestSerializerTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-07-16.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import PiuPiu
@testable import Example

class RequestSerializerTests: XCTestCase, ServerProvider {
    
    var baseURL: URL? {
        return URL(string: "https://jsonplaceholder.typicode.com/posts/1")
    }

    private let instantDispatcher = MockURLRequestDispatcher(delay: 0, callback: { request in
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
    
    func testSendRequest() {
        // When
        var calledCompletion = false
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        let errorExpectation = self.expectation(description: "Error triggered")
        errorExpectation.isInverted = true
        
        // Given
        let networkSerializer = RequestSerializer(dispatcher: instantDispatcher, serverProvider: self)
        let request = BasicRequest(method: .get, path: "/posts/1")
        
        // Then
        networkSerializer.dataFuture(from: request).then({ response -> Post in
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
        }).response({ post in
            // The final response callback includes all the transformations and
            // Joins we had previously performed.
            XCTAssertFalse(calledCompletion)
            successExpectation.fulfill()
        }).error({ error in
            XCTAssertFalse(calledCompletion)
            errorExpectation.fulfill()
        }).completion({
            XCTAssertFalse(calledCompletion)
            calledCompletion = true
            completionExpectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
