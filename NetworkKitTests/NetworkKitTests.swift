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
    
    struct MockCodable2: Codable, Equatable {
        var uuid2: String
        
        init() {
            self.uuid2 = UUID().uuidString
        }
        
        public static func == (lhs: MockCodable2, rhs: MockCodable2) -> Bool {
            return lhs.uuid2 == rhs.uuid2
        }
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
            successExpectation.fulfill()
            XCTAssertEqual(response.statusCode, StatusCode.ok)
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
            failureExpectation.fulfill()
            XCTAssertEqual(response.statusCode, statusCode)
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
            successExpectation.fulfill()
            XCTAssertEqual(response.statusCode, StatusCode.ok)
            XCTAssertEqual(response.data, responseObject)
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
        
        dispatcher.make(request).deserialize(to: MockCodable2.self).success({ response in
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

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
