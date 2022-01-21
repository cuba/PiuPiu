//
//  RequestSerializerTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-07-16.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
import PiuPiu
@testable import Example

class RequestSerializerTests: XCTestCase, ServerProvider {
    var baseURL: URL? {
        return URL(string: "https://jsonplaceholder.typicode.com")
    }

    private lazy var dispatcher: URLRequestDispatcher = {
        return URLRequestDispatcher(requestAdapter: self, responseAdapter: MockHTTPResponseAdapter.success)
    }()
    
    func testSendRequest() {
        // When
        var calledCompletion = false
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        // Given
        let networkSerializer = RequestSerializer(dispatcher: dispatcher, serverProvider: self)
        let request = BasicRequest(method: .get, path: "/posts/1")
        
        // Then
        networkSerializer.dataFuture(from: request)
            .then(Post.self) { response in
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
            .success { post in
                // The final response callback includes all the transformations and
                // Joins we had previously performed.
                XCTAssertFalse(calledCompletion)
                successExpectation.fulfill()
            }
            .error { error in
                XCTAssertFalse(calledCompletion)
                XCTFail("Should not be triggered")
            }
            .completion {
                XCTAssertFalse(calledCompletion)
                calledCompletion = true
                completionExpectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}

extension RequestSerializerTests: URLRequestAdapter {
    func adapt(urlRequest: URLRequest, with callback: @escaping (URLRequest) throws -> Void) throws {
        // In order to not make real api calls we will cheat
        var urlRequest = urlRequest
        urlRequest.url = MockJSON.post.url
        try callback(urlRequest)
    }
}
