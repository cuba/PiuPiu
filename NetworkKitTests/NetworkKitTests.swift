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
        let request = BasicRequest(method: .get, path: "")
        
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
        let request = BasicRequest(method: .get, path: "")
        
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
    
    func testSuccessfulEncodableSerialization() {
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        
        // When
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        dispatcher.makeRequest(from: {
            var request = BasicRequest(method: .post, path: "")
            let requestObject = MockCodable()
            try request.setHTTPBody(requestObject)
            return request
        }).success({ response in
            // Then
            XCTAssertEqual(response.statusCode, StatusCode.ok)
            successExpectation.fulfill()
        }).failure({ response in
            XCTFail("Should not trigger the failure")
        }).error({ error in
            XCTFail("Should not trigger the error")
        }).completion({
            completionExpectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnsuccessfulEncodableSerialization() {
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        
        // When
        let errorExpectation = self.expectation(description: "Error callback triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        dispatcher.makeRequest(from: {
            throw ResponseError.badRequest(cause: nil)
        }).success({ response in
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
    
    func testSuccessfulCodableDeserialization() {
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        let request = BasicRequest(method: .get, path: "")
        let responseObject = MockCodable()
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        do {
            try dispatcher.setMockData(responseObject)
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        dispatcher.make(request).then({ response -> MockCodable in
            XCTAssertEqual(response.statusCode, StatusCode.ok)
            
            // When
            return try response.decode(MockCodable.self)
        }).success({ decodable in
            // Then
            XCTAssertEqual(decodable, responseObject)
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
        let request = BasicRequest(method: .get, path: "")
        let responseObject = MockCodable()
        
        do {
            try dispatcher.setMockData(responseObject)
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        // When
        let errorExpectation = self.expectation(description: "Error response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        dispatcher.make(request).then({ response in
            // When
            return try response.decode(MockDecodable.self)
        }).success({ response in
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
        var request = BasicRequest(method: .get, path: "")
        
        // Then
        XCTAssertNoThrow(try request.setHTTPBody(codable), "Should not fail serialization")
        XCTAssertNotNil(request.httpBody)
    }
    
    func testSuccessfulJSONObjectSerialization() {
        // Given
        var request = BasicRequest(method: .get, path: "")
        
        let jsonObject: [String: Any?] = [
            "id": "123",
            "name": "Kevin Malone"
        ]
        
        // Then
        XCTAssertNoThrow(try request.setHTTPBody(jsonObject: jsonObject), "Should not fail serialization")
        XCTAssertNotNil(request.httpBody)
    }
    
    func testSuccessfulJSONStringSerialization() {
        // Given
        var request = BasicRequest(method: .get, path: "")
        
        let jsonString = """
            {
                "id": "123",
                "name": "Kevin Malone"
            }
        """
        
        // Then
        request.setHTTPBody(string: jsonString)
        XCTAssertNotNil(request.httpBody)
    }
    
    func testWrappedPromise() {
        // Given
        let codable = MockCodable()
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        let request = BasicRequest(method: .get, path: "/posts")
        
        Promise<MockCodable, MockDecodable>(action: { promise in
            try dispatcher.setMockData(codable)
            
            // When
            dispatcher.make(request).then({ response in
                return try response.decode(MockCodable.self)
            }).thenFailure({ response in
                return try response.decode(MockDecodable.self)
            }).fullfill(promise)
        }).success({ response in
            // Then
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
