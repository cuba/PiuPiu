//
//  NetworkKitTests.swift
//  NetworkKitTests
//
//  Created by Jacob Sikorski on 2019-02-16.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import NetworkKit

class NetworkKitTests: XCTestCase {
    struct MockCodable: Codable, Equatable {
        var uuid: String
        
        init() {
            self.uuid = UUID().uuidString
        }
        
        public static func == (lhs: MockCodable, rhs: MockCodable) -> Bool {
            return lhs.uuid == rhs.uuid
        }
    }
    
    struct MockDecodable: Decodable {
        let message: String
    }

    func testSuccessfulDataResponse() {
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        let request = JSONRequest(method: .get, path: "")
        
        // When
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        dispatcher.make(request).success({ response in
            // Then
            XCTAssertEqual(response.statusCode, StatusCode.ok)
            successExpectation.fulfill()
        }).failure({ response in
            XCTFail("Should not trigger the failure")
        }).completion({
            completionExpectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnsuccessfulDataResponse() {
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let statusCode = StatusCode.badRequest
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: statusCode, mockError: statusCode.makeError(cause: nil))
        let request = JSONRequest(method: .get, path: "")
        
        // When
        let failureExpectation = self.expectation(description: "Error response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        dispatcher.make(request).success({ response in
            // Then
            XCTFail("Should not trigger the success")
        }).failure({ response in
            XCTAssertEqual(response.statusCode, statusCode)
            failureExpectation.fulfill()
        }).completion({
            completionExpectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSuccessfulCodableDeserialization() {
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        let request = JSONRequest(method: .get, path: "")
        let responseObject = MockCodable()
        
        do {
            try dispatcher.setMockData(responseObject)
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        // When
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        dispatcher.make(request).deserialize(to: MockCodable.self).success({ response in
            // Then
            XCTAssertEqual(response.statusCode, StatusCode.ok)
            XCTAssertEqual(response.data, responseObject)
            successExpectation.fulfill()
        }).failure({ response in
            XCTFail("Should not trigger the failure")
        }).completion({
            completionExpectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnsuccessfulCodableDeserialization() {
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        let request = JSONRequest(method: .get, path: "")
        let responseObject = MockCodable()
        
        do {
            try dispatcher.setMockData(responseObject)
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        // When
        let errorExpectation = self.expectation(description: "Error response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        dispatcher.make(request).deserialize(to: MockDecodable.self).success({ response in
            // Then
            XCTFail("Should not trigger the success")
        }).failure({ response in
            XCTFail("Should not trigger the failure")
        }).error({ error in
            errorExpectation.fulfill()
        }).completion({
            completionExpectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSuccessfulCodableSerialization() {
        // Given
        let codable = MockCodable()
        var request = JSONRequest(method: .get, path: "")
        
        // Then
        XCTAssertNoThrow(try request.setHTTPBody(codable), "Should not fail serialization")
        XCTAssertNotNil(request.httpBody)
    }
    
    func testSuccessfulJSONStringSerialization() {
        // Given
        var request = JSONRequest(method: .get, path: "")
        
        let jsonObject: [String: Any?] = [
            "id": "123",
            "name": "Kevin Malone"
        ]
        
        // Then
        XCTAssertNoThrow(try request.setHTTPBody(jsonObject: jsonObject), "Should not fail serialization")
        XCTAssertNotNil(request.httpBody)
    }
    
    func testWrappedPromise() {
        // Given
        let codable = MockCodable()
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        let request = JSONRequest(method: .get, path: "/posts")
        
        // When
        Promise<MockCodable, MockDecodable>(action: { promise in
            try dispatcher.setMockData(codable)
            
            let requestPromise = dispatcher.make(request).deserialize(to: MockCodable.self).deserializeError(to: MockDecodable.self)
            
            requestPromise.then({ response -> MockCodable in
                return response.data
            }).thenFailure({ response -> MockDecodable in
                return response.data
            }).fullfill(promise)
        }).success({ response in
            XCTAssertEqual(response, codable)
            successExpectation.fulfill()
        }).failure({ mockDecodable in
            XCTFail("Should not trigger the failure")
        }).error({ error in
            XCTFail("Should not trigger the error")
        }).completion({
            completionExpectation.fulfill()
        }).start()
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
