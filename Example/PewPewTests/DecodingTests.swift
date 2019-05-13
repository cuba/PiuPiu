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
    func testUnwrappingData() {
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        let request = BasicRequest(method: .get, path: "/posts/1")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        do {
            try dispatcher.setMockData(post)
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        // Example
        dispatcher.future(from: request).response({ response in
            let data = try response.unwrapData()
            
            // do something with data.
            print(data)
        }).error({ error in
            // Triggered when unwrapData fails.
        }).completion({
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDecodingString() {
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        let request = BasicRequest(method: .get, path: "/posts/1")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        do {
            try dispatcher.setMockData(post)
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        // Example
        dispatcher.future(from: request).response({ response in
            let string = try response.decodeString(encoding: .utf8)
            
            // do something with string.
            print(string)
        }).error({ error in
            // Triggered when decoding fails.
        }).completion({
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDecodingDecodable() {
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        let request = BasicRequest(method: .get, path: "/posts/1")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        do {
            try dispatcher.setMockData(post)
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        // Example
        dispatcher.future(from: request).response({ response in
            let posts = try response.decode(Post.self)
            
            // do something with string.
            print(posts)
        }).error({ error in
            // Triggered when decoding fails.
        }).completion({
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDecodingMapDecodable() {
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        let request = BasicRequest(method: .get, path: "/posts/1")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        do {
            try dispatcher.setMockData(post)
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        // Example
        dispatcher.future(from: request).response({ response in
            let post = try response.decodeMapDecodable(MapCodablePost.self)
            
            // do something with string.
            print(post)
        }).error({ error in
            // Triggered when decoding fails.
        }).completion({
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDecodingMapDecodableArray() {
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        let request = BasicRequest(method: .get, path: "/posts")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        do {
            try dispatcher.setMockData([post])
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        // Example
        dispatcher.future(from: request).response({ response in
            let posts = try response.decodeMapDecodable([MapCodablePost].self)
            
            // do something with string.
            print(posts)
        }).error({ error in
            // Triggered when decoding fails.
            print(error)
        }).completion({
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnsuccessfulCodableDeserialization() {
        // Given
        
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        let request = BasicRequest(method: .get, path: "/posts")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        do {
            try dispatcher.setMockData([post])
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        // When
        
        let errorExpectation = self.expectation(description: "Error response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        // Then
        
        dispatcher.promise(from: request).then({ response in
            // When
            return try response.decode(Post.self)
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
}
