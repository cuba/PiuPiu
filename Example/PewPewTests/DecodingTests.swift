//
//  TestDecoding.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-04-13.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import PiuPiu
@testable import Example

class DecodingTests: XCTestCase {
    private let dispatcher = MockURLRequestDispatcher(delay: 0.5, callback: { request in
        if let id = request.integerValue(atIndex: 1, matching: [.constant("posts"), .wildcard(type: .integer)]) {
            let post = Post(id: id, userId: 123, title: "Some post", body: "Lorem ipsum ...")
            return try Response.makeMockJSONResponse(with: request, encodable: post, statusCode: .ok)
        } else if request.pathMatches(pattern: [.constant("posts")]) {
            let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
            return try Response.makeMockJSONResponse(with: request, encodable: [post], statusCode: .ok)
        } else {
            return Response.makeMockResponse(with: request, statusCode: .notFound)
        }
    })
    
    func testUnwrappingData() {
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        let request = URLRequest(url: url, method: .get)
        
        // Example
        dispatcher.dataFuture(from: request)
            .success { response in
                let data = try response.unwrapData()
                
                // do something with data.
                print(data)
            }
            .error { error in
                // Triggered when unwrapData fails.
            }
            .completion {
                expectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDecodingString() {
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        let request = URLRequest(url: url, method: .get)
        
        // Example
        dispatcher.dataFuture(from: request)
            .success { response in
                let string = try response.decodeString(encoding: .utf8)
                
                // do something with string.
                print(string)
            }
            .error { error in
                // Triggered when decoding fails.
            }
            .completion {
                expectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDecodingDecodable() {
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        let request = URLRequest(url: url, method: .get)
        
        // Example
        dispatcher.dataFuture(from: request)
            .success { response in
                let posts = try response.decode(Post.self)
                
                // do something with string.
                print(posts)
            }
            .error { error in
                // Triggered when decoding fails.
            }
            .completion {
                expectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnsuccessfulCodableDeserialization() {
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        let request = URLRequest(url: url, method: .get)
        
        // When
        let errorExpectation = self.expectation(description: "Error response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        // Then
        dispatcher.dataFuture(from: request)
            .then { response in
                // When
                return try response.decode(Post.self)
            }
            .success { response in
                // Then
                XCTFail("Should not trigger the success")
            }
            .error { error in
                errorExpectation.fulfill()
            }
            .completion {
                completionExpectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testResponseFutureDecodedMethodDeserialization() {
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        let request = URLRequest(url: url, method: .get)
        
        // When
        let errorExpectation = self.expectation(description: "Error response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        // Then
        dispatcher.dataFuture(from: request)
            .decoded(Post.self)
            .success { response in
                // Then
                XCTFail("Should not trigger the success")
            }
            .error { error in
                errorExpectation.fulfill()
            }
            .completion {
                completionExpectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testResponseFutureSafeDecodedMethodDeserialization() {
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        let request = URLRequest(url: url, method: .get)
        
        // When
        let successExpectation = self.expectation(description: "Error response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        // Then
        dispatcher.dataFuture(from: request)
            .makeHTTPResponse()
            .safeDecoded(Post.self)
            .safeResult()
            .success { result in
                switch result {
                case .success(let response):
                    switch response.data {
                    case .success:
                        XCTFail("Should not trigger the success")
                    case .failure:
                        // Then
                        successExpectation.fulfill()
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }
            .error { error in
                XCTFail("Should not trigger the failure")
            }
            .completion {
                completionExpectation.fulfill()
            }
            .send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
