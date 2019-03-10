//
//  DocumentationExamples.swift
//  NetworkKitTests
//
//  Created by Jacob Sikorski on 2019-02-20.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import NetworkKit

class DocumentationExamples: XCTestCase, ServerProvider {
    
    struct Post: Codable {
        let id: Int
        let userId: Int
        let title: String
        let body: String
    }
    
    struct ServerErrorDetails: Codable {
    }
    
    struct User: Codable {
        // TODO: Make this MapCodable to test properly.
        
        var id: Int
        var name: String
    }
    
    var baseURL: URL {
        return URL(string: "https://jsonplaceholder.typicode.com")!
    }

    func testPostExample() {
        let expectation = self.expectation(description: "Success response triggered")
        
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = JSONRequest(method: .get, path: "/posts")
        
        dispatcher.make(request).success({ response in
            let posts = try response.decode([Post].self)
            print(posts)
            // This method is triggered when a 2xx response comes in.
        }).failure({ response in
            // This method is triggered when a non 2xx response comes in.
            // All errors in the response object are ResponseError
            if let message = try? response.decodeString(encoding: .utf8) {
                print(message)
            }
        }).error({ error in
            // Triggers whenever an error is thrown.
            // This includes deserialization errors, unwraping failures, and anything else that is thrown
            // in a `success`, `error`, `then` or `thenFailure` block in any chained promise.
            // These errors are often application related errors but can be caused
            // because of invalid server responses (example: when deserializing the response data).
            print(error)
        }).completion({
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAddDataToRequest() {
        // Given
        let myData = Data(count: 0)
        
        var request = JSONRequest(method: .post, path: "/users")
        request.httpBody = myData
    }
    
    func testEncodeJsonString() {
        // Given
        let jsonString = """
            {
                "name": "Jim Halpert"
            }
        """
        
        // Example
        var request = JSONRequest(method: .post, path: "/users")
        request.setHTTPBody(string: jsonString, encoding: .utf8)
    }
    
    func testEncodeJsonObject() {
        do {
            let jsonObject: [String: Any?] = [
                "id": "123",
                "name": "Kevin Malone"
            ]
            
            var request = JSONRequest(method: .post, path: "/users")
            try request.setHTTPBody(jsonObject: jsonObject)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testEncodeEncodable() {
        let myCodable = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        do {
            var request = JSONRequest(method: .post, path: "/posts")
            try request.setHTTPBody(encodable: myCodable)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testEncodeMapEncodable() {
        // TODO
    }
    
    func testWrapEncodingInAPromise() {
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let myCodable = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        // Example
        dispatcher.make(from: {
            var request = JSONRequest(method: .post, path: "")
            try request.setHTTPBody(myCodable)
            return request
        }).error({ error in
            // Any error thrown while creating the request will trigger this callback.
        }).completion({
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnwrappingData() {
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = JSONRequest(method: .get, path: "/posts")
        
        // Example
        dispatcher.make(request).success({ response in
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
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = JSONRequest(method: .get, path: "/posts")
        
        // Example
        dispatcher.make(request).success({ response in
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
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = JSONRequest(method: .get, path: "/posts/1")
        
        // Example
        dispatcher.make(request).success({ response in
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
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = JSONRequest(method: .get, path: "/users/1")
        
        // Example
        dispatcher.make(request).success({ response in
            let post = try response.decode(User.self)
            
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
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = JSONRequest(method: .get, path: "/users")
        
        // Example
        dispatcher.make(request).success({ response in
            let posts = try response.decode([User].self)
            
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
    
    func testTransform() {
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let request = self.fetchPost(id: "1")
        
        // Then
        request.success({ post in
            // When everything succeeds including the network call and deserialization
            print(post)
        }).failure({ serverError in
            // Triggered when network call fails
            // and the deserialization of the error object succeeds.
            print(serverError)
        }).error({ error in
            // Triggered when internal error occurs.
            // Includes errors caused durin the deserialization
            // of the success response or the error response
            print(error)
        }).completion({
            expectation.fulfill()
        }).send()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAdvancedPromise() {
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = JSONRequest(method: .get, path: "/posts/1")
        
        Promise<Post, ServerErrorDetails>(action: { promise in
            // `fullfill` calls the succeed and fail methods.
            // The promise that is fullfilling another promise must be transformed
            // first using `then` and `thenFailure` so that it is of the same type
            // before the fullfill method can be called.
            // You may also succeed or fail the promise manually.
            // `fulfill `calls `start` so there is no need to call it.
            
            dispatcher.make(request).then({ response in
                // `then` callback is triggered only when a successful response comes back.
                return try response.decode(Post.self)
            }).thenFailure({ response in
                // `thenFailure` callback is triggered only when an unsusccessful response comes back.
                return try response.decode(ServerErrorDetails.self)
            }).fullfill(promise)
        }).success({ post in
            // Then
            print(post)
        }).failure({ serverError in
            print(serverError)
        }).error({ error in
            print(error)
        }).completion({
            // Perform operation on completion
            expectation.fulfill()
        }).start()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
    /// Make a API call to retrieve a post by its id.
    /// Transform the response to return a Post or a ServerErrorDetails.
    /// NOTE: `ServerErrorDetails` is a custom object that does not come with `NetworkKit`.
    ///
    /// - Parameter id: The id of the post.
    /// - Returns: A promise that expects a Post succcess object or a ServerErrorDatails failure object.
    private func fetchPost(id: String) -> Promise<Post, ServerErrorDetails> {
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = JSONRequest(method: .get, path: "/posts/\(id)")
        
        return dispatcher.make(request).then({ response in
            // Return the transformed object
            // In this case the transformed object will be a decoded post
            // Note: a throwing failure will trigger the `error` callback.
            // Any unhandled throws in a `make`, `success`, `failure`, `then`, or `thenFailure`
            // block will trigger the `error` callback.
            return try response.decode(Post.self)
        }).thenFailure({ response in
            // Return the transformed object
            // In this case the transformed object will be a decoded ServerDetailsError object
            // Note: a throwing failure will trigger the `error` callback.
            // You may consider doing non-failing decoding here since
            // server errors may be unpredictable and you can't guarantee a specific
            // response object. You may also check the status code or the response before
            // doing your decoding.
            
            return try response.decode(ServerErrorDetails.self)
        })
    }
}
