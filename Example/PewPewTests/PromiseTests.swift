//
//  PewPewTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-02-16.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import PewPew
@testable import Example

class PromiseTests: XCTestCase {
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
    
    struct ServerErrorDetails: Codable {
        let message: String
        
        init(message: String) {
            self.message = message
        }
    }

    func testSuccessfulDataResponse() {
        // Given
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: .ok)
        let request = BasicRequest(method: .get, path: "")
        
        // When
        let successExpectation = self.expectation(description: "Success response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        dispatcher.promise(from: request).success({ response in
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
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: statusCode)
        let request = BasicRequest(method: .get, path: "")
        
        // When
        let failureExpectation = self.expectation(description: "Error response triggered")
        let completionExpectation = self.expectation(description: "Completion triggered")
        
        dispatcher.promise(from: request).success({ response in
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
        
        dispatcher.promise(from: {
            var request = BasicRequest(method: .post, path: "")
            let requestObject = MockCodable()
            try request.setJSONBody(requestObject)
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
        
        dispatcher.promise(from: {
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
        
        dispatcher.promise(from: request).then({ response -> MockCodable in
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
    
    func testPromise() {
        // Given
        
        let expectation = self.expectation(description: "Success response triggered")
        let request = BasicRequest(method: .get, path: "/posts")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let dispatcher = makePostDispatcher(with: post)
        let response = try! dispatcher.response(from: request)
        
        // Then
        
        makePromise(from: response).success({ post in
            expectation.fulfill()
        }).start()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    private func makePromise(from response: Response<Data?>) -> Promise<Post, Error> {
        // Promises can wrap callbacks so they are executed when start()
        // is triggered.
        return Promise<Post, Error>(action: { promise in
            // This is an example of how a promise is executed and
            // fulfilled.
            
            // You should always syncronize
            DispatchQueue.global(qos: .userInitiated).async {
                // lets make an expensive operation on a background thread.
                
                do {
                    // Do an expensive operation here ....
                    // The below is just an example of how you can parse on a seperate thread.
                    let post = try response.decode(Post.self)
                    
                    // We should syncronyze the result back to the main thread.
                    // If we don't do this now, or at some point, we will have some
                    // Unexpected results.
                    DispatchQueue.main.async {
                        promise.succeed(with: post)
                    }
                } catch {
                    // We can handle any errors as well.
                    // We should also syncronize the error to the main thread.
                    DispatchQueue.main.async {
                        promise.catch(error)
                        
                        // Optionally we can also do this:
                        // promise.fail(with: error)
                        
                        // The difference is that fail will be triggered in the `failure` callback
                        // and `catch` will be triggered on the `error` callback.
                    }
                }
            }
        })
    }
    
    // MARK: - Callbacks
    func testPromiseCallback() {
        // Given
        let expectation = self.expectation(description: "Success response triggered")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let dispatcher = makePostDispatcher(with: post)
        
        // Then
        
        dispatcher.promise(from: {
            var request = BasicRequest(method: .post, path: "/post")
            try request.setJSONBody(post)
            return request
        }).success({ response in
            // When everything succeeds including the network call and deserialization
            expectation.fulfill()
        }).start()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSuccessCallback() {
        // Given
        
        let expectation = self.expectation(description: "Success response triggered")
        let request = BasicRequest(method: .get, path: "/posts")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let dispatcher = makePostDispatcher(with: post)
        
        // Then
        
        dispatcher.promise(from: request).success({ response in
            // When everything succeeds including the network call and deserialization
            expectation.fulfill()
        }).start()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testThenCallback() {
        // Given
        let expectation = self.expectation(description: "Success response triggered")
        let request = BasicRequest(method: .get, path: "/posts")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let dispatcher = makePostDispatcher(with: post)
        
        // Then
        
        dispatcher.promise(from: request).then({ response -> Post in
            // The `then` callback transforms a successful response
            // You can return any object here and this will be reflected on the success callback.
            return try response.decode(Post.self)
        }).success({ post in
            // Handles the successfully parsed object in the `then` callback
            expectation.fulfill()
        }).start()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testThenFailureCallback() {
        // Given
        let expectation = self.expectation(description: "Success response triggered")
        let request = BasicRequest(method: .get, path: "/posts")
        let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let dispatcher = makePostDispatcher(with: post, status: .badRequest)
        
        do {
            try dispatcher.setMockData(encodable: ServerErrorDetails(message: "Failure!"))
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        // Then
        
        dispatcher.promise(from: request).thenFailure({ response -> ServerErrorDetails? in
            // The `thenFailure` callback transforms a failed response.
            // You can return any object here and this will be reflected on the `failure` callback.
            do {
                let errorDetails = try response.decode(ServerErrorDetails.self)
                return errorDetails
            } catch {
                // Note: If you do parse the error object, you should make this non-failing
                // since server errors can be unpredictable, especially in the case of 5xx errors.
                throw response.error
            }
        }).failure({ errorDetails in
            // Handles the object returned in the `thenFailure` callback
            expectation.fulfill()
        }).error({ error in
            // Handles all other errors including anything
            // we throw in the `thenFailure` callback.
        }).start()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    private func makePostDispatcher<T: Encodable>(with response: T, status: StatusCode = .ok) -> MockDispatcher {
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: status)
        
        do {
            try dispatcher.setMockData(response)
        } catch {
            XCTFail("Should not fail serialization")
        }
        
        return dispatcher
    }
}
