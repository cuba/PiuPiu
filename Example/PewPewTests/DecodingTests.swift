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
    private lazy var fileDispatcher: URLRequestDispatcher = {
        return URLRequestDispatcher(responseAdapter: MockHTTPResponseAdapter.success)
    }()
    
    func testUnwrappingData() {
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let request = URLRequest(url: MockJSON.posts.url, method: .get)
        
        // Example
        fileDispatcher.dataFuture(from: request)
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
        let request = URLRequest(url: MockJSON.posts.url, method: .get)
        
        // Example
        fileDispatcher.dataFuture(from: request)
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
        let request = URLRequest(url: MockJSON.post.url, method: .get)
        
        // Example
        fileDispatcher.dataFuture(from: request)
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
        let request = URLRequest(url: MockJSON.posts.url, method: .get)
        
        // When
        let errorExpectation = self.expectation(description: "Error response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        // Then
        fileDispatcher.dataFuture(from: request)
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
        let request = URLRequest(url: MockJSON.posts.url, method: .get)
        
        // When
        let errorExpectation = self.expectation(description: "Error response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        // Then
        fileDispatcher.dataFuture(from: request)
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
        let request = URLRequest(url: MockJSON.posts.url, method: .get)
        
        // When
        let successExpectation = self.expectation(description: "Error response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        // Then
        fileDispatcher.dataFuture(from: request)
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
