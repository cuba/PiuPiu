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
        var id: Int
        var userId: Int
        var title: String
        var body: String
    }
    
    
    struct ServerError: Codable {
        
    }
    
    var baseURL: URL {
        return URL(string: "https://jsonplaceholder.typicode.com")!
    }

    func testPostExample() {
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
        }).send()
    }
    
    func testAddDataToRequest() {
        // Given
        let myData = Data(count: 0)
        
        var request = JSONRequest(method: .post, path: "/users")
        request.httpBody = myData
    }
    
    func testAddJsonStringToRequest() {
        // Given
        let jsonString = """
            {
                "name": "Jim Halpert"
            }
        """
        
        // Example
        var request = JSONRequest(method: .post, path: "/users")
        request.setHTTPBody(jsonString: jsonString, encoding: .utf8)
    }
    
    func addJsonObjectToRequest() {
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
    
    func addEncodableToRequest() {
        let myCodable = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        do {
            var request = JSONRequest(method: .post, path: "/posts")
            try request.setHTTPBody(encodable: myCodable)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func addMapEncodableToRequest() {
        // TODO
    }
    
    func wrapEncodingInAPromise() {
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
        }).send()
    }
    
    func unwrappingData() {
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
        }).send()
    }
    
    func decodingString() {
        // Given
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = JSONRequest(method: .get, path: "/posts")
        
        // Example
        dispatcher.make(request).success({ [weak self] response in
            let string = try response.decodeString(encoding: .utf8)
            
            // do something with string.
            print(string)
        }).error({ error in
            // Triggered when decoding fails.
        }).send()
    }
    
    func decodingCodable() {
        // Given
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = JSONRequest(method: .get, path: "/posts")
        
        // Example
        dispatcher.make(request).success({ [weak self] response in
            let posts = try response.decode([Post].self)
            
            // do something with string.
            print(posts)
        }).error({ error in
            // Triggered when decoding fails.
        }).send()
    }
    
    func decodingMapCodableArray() {
        // Given
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = JSONRequest(method: .get, path: "/posts")
        
        // Example
        dispatcher.make(request).success({ [weak self] response in
            let posts = try response.decode([Post].self)
            
            // do something with string.
            print(posts)
        }).error({ error in
            // Triggered when decoding fails.
        }).send()
    }
    
    func decodingMapCodable() {
        // Given
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = JSONRequest(method: .get, path: "/posts/1")
        
        // Example
        dispatcher.make(request).success({ [weak self] response in
            let post = try response.decode(Post.self)
            
            // do something with string.
            print(post)
        }).error({ error in
            // Triggered when decoding fails.
        }).send()
    }
    
    func advancedPromise() {
        // Given
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = JSONRequest(method: .get, path: "/posts/1")
        
        Promise<[Post], ServerError>(action: { promise in
            // `fullfill` calls the succeed and fail methods. The promise that is fullfilling another promise must be transformed first using `then` and `thenFailure` so that it is of the same type.
            // You may also succeed or fail the promise manually.
            // `fulfill `calls `start` so there is no need to call it.
            
            dispatcher.make(request).then({ response in
                // `then` callback is triggered only when a successful response comes back.
                return try response.decode([Post].self)
            }).thenFailure({ response in
                // `thenFailure` callback is triggered only when an unsusccessful response comes back.
                return try response.decode(ServerError.self)
            }).fullfill(promise)
        }).success({ posts in
            // Then
            print(posts)
        }).failure({ serverError in
            print(serverError)
        }).error({ error in
            print(error)
        }).completion({
            // Perform operation on completion
        }).start()
    }
}
