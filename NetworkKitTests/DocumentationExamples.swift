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
        let id: Int?
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
    
    private var strongPromise: ResponsePromise<[Post], Data?>?
    private weak var weakPromise: ResponsePromise<Data?, Data?>?

    func testPostExample() {
        let expectation = self.expectation(description: "Success response triggered")
        
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = BasicRequest(method: .get, path: "/posts")
        
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
        
        var request = BasicRequest(method: .post, path: "/users")
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
        var request = BasicRequest(method: .post, path: "/users")
        request.setHTTPBody(string: jsonString, encoding: .utf8)
    }
    
    func testEncodeJsonObject() {
        do {
            let jsonObject: [String: Any?] = [
                "id": "123",
                "name": "Kevin Malone"
            ]
            
            var request = BasicRequest(method: .post, path: "/users")
            try request.setHTTPBody(jsonObject: jsonObject)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testEncodeEncodable() {
        let myCodable = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        do {
            var request = BasicRequest(method: .post, path: "/posts")
            try request.setJSONBody(encodable: myCodable)
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
        dispatcher.makeRequest(from: {
            var request = BasicRequest(method: .post, path: "")
            try request.setJSONBody(myCodable)
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
        let request = BasicRequest(method: .get, path: "/posts")
        
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
        let request = BasicRequest(method: .get, path: "/posts")
        
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
        let request = BasicRequest(method: .get, path: "/posts/1")
        
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
        let request = BasicRequest(method: .get, path: "/users/1")
        
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
        let request = BasicRequest(method: .get, path: "/users")
        
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
    
    func testFullConvertExample() {
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let newPost = Post(id: nil, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        dispatcher.makeRequest(from: {
            /// Here we can construct our request.
            /// Any errors will throw here will be handled in the `error` callback.
            /// So we can deal with them in one place.
            /// Note (the errors thrown here are likely due to programmer mistakes).
            /// Nowever you may chose to do some a validation here.
            var request = BasicRequest(method: .post, path: "/posts")
            try request.setJSONBody(newPost)
            return request
        }).future({ response in
            /// Convert the `Promise` to a `ResponseFuture` This forces us to convert
            /// failed response callback to an error.
            
            /// NOTE: This callback will change the object from a `Promise` to a `ResponseFuture`
            /// You will no longer have access to callbacks like `thenFailure`, `success` or `failed`.
            
            /// We transform the failed response to anything we want
            /// We can even parse the response body to get a server error object.
            /// for now we will just return the response error.
            return response.error
        }).then({ response -> Post in
            return try response.decode(Post.self)
        }).response({ post in
            /// We already transformed the success request
            /// Handles any successful responses.
            /// In this case the object returned in the `then` method.
        }).error({ error in
            /// Handles any errors during the request process,
            /// including all request creation errors and anything
            /// thrown in the `then` or `success` callbacks or returned
            /// in the `future` callback.
        }).completion({
            /// The completion callback guaranteed to be called once
            /// for every time the `start` method is triggered on the callback.
        }).send()
    }
    
    func testFullResponseFutureExample() {
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let newPost = Post(id: nil, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        dispatcher.future(from: {
            var request = BasicRequest(method: .post, path: "/posts")
            try request.setJSONBody(newPost)
            return request
        }).then({ response -> Post in
            // Handles any responses and transforms them to another type
            // This includes negative responses such as 400s and 500s
            
            if let error = response.error {
                // We throw the error so we can handle it in the `error` callback.
                // We can also handle the error response in a more custom way if we chose.
                throw error
            } else {
                // if we have no error, we just return the decoded object
                // If anything is thrown, it will be caught in the `error` callback.
                return try response.decode(Post.self)
            }
        }).response({ post in
            // Handles any success responses.
            // In this case the object returned in the `then` method.
        }).error({ error in
            // Handles any errors during the request process,
            // including all request creation errors and anything
            // thrown in the `then` or `success` callbacks.
        }).completion({
            // The completion callback guaranteed to be called once
            // for every time the `start` method is triggered on the callback.
        }).send()
    }
    
    func testFullPromiseExample() {
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = BasicRequest(method: .get, path: "/posts")
        
        dispatcher.make(request).then({ response -> Post in
            // The `then` callback transforms a successful response
            return try response.decode(Post.self)
        }).thenFailure({ response -> ServerErrorDetails in
            // The `thenFailure` callback transforms a failed response
            return try response.decode(ServerErrorDetails.self)
        }).success({ post in
            // Handles any success responses.
            // In this case the object returned in the `then` method.
        }).failure({ serverError in
            // Handles any graceful errors.
            // In this case the object returned in the `thenFailure` method.
        }).error({ error in
            // Handles any ungraceful errors.
            // This includes deserialization errors, unwraping failures, and anything else that is thrown
            // in a `make`, `success`, `error`, `then` or `thenFailure` block in any chained promise.
        }).completion({
            // The completion callback guaranteed to be called once
            // for every time the `send` or `start` method is triggered on the callback.
        }).send()
    }
    
    func testPromiseFromResponseFutureExample() {
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = BasicRequest(method: .get, path: "/posts")
        
        dispatcher.make(request).future({ failedResponse in
            // Sice a `SimplePromse` does not handle `failure` callbacks,
            // we have to transform this to an `Error` object.
            // This is triggered when a failed response is recieved
            // But it always transforms the `FutreResponse` to a `Promse`.
            
            // You can simply return the response error or return something a little more custom
            // NOTE: You may want to use `dispatcher.promise(from: request)` instead.
            return failedResponse.error
        }).response({ response in
            // A success response. Because we used a Promise, this returns a `SuccessResponse`.
            // However we can have had a bit more control, if we used `dispatcher.promise(from: request)` directly.
        }).error({ error in
            // This handles all errors thrown during the request creation process and
            // the error returned in the `promise` callback.
        }).completion({
            // Always triggered for every time we trigger `start()`
        }).send()
    }
    
    func testMakeRequestCallback() {
        let newPost = Post(id: nil, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let dispatcher = NetworkDispatcher(serverProvider: self)
        
        dispatcher.makeRequest(from: {
            var request = BasicRequest(method: .post, path: "/post")
            try request.setJSONBody(newPost)
            return request
        }).send()
        
        
        let request = BasicRequest(method: .get, path: "/posts")
        dispatcher.make(request).send()
    }
    
    func testSuccessCallback() {
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = BasicRequest(method: .get, path: "/posts")
        
        dispatcher.make(request).success({ response in
            // When everything succeeds including the network call and deserialization
        }).send()
    }

    func testThenCallback() {
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = BasicRequest(method: .get, path: "/posts")
        
        dispatcher.make(request).then({ response -> SuccessResponse<Post> in
            // The `then` callback transforms a successful response
            // You can return any object here and this will be reflected on the success callback.
            let post = try response.decode(Post.self)
            return SuccessResponse<Post>(data: post, response: response)
        }).success({ post in
            // Handles any success responses.
            // In this case the object returned in the `then` method.
        }).send()
    }
    
    func testThenFailureCallback() {
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = BasicRequest(method: .get, path: "/posts")
        
        dispatcher.make(request).thenFailure({ response -> ErrorResponse<ServerErrorDetails?> in
            // The `thenFailure` callback transforms a failed response.
            // You can return any object here and this will be reflected on the failure callback.
            
            // Note: You should make this non-failing since server errors can be unpredictable,
            // especially in the case of 5xx errors.
            let post = try? response.decode(ServerErrorDetails.self)
            return ErrorResponse<ServerErrorDetails?>(data: post, response: response)
        }).failure({ response in
            // Handles any failed responses.
            // In this case the object returned in the `thenFailure` method.
        }).send()
    }
    
    func testWeakCallbacks() {
        let expectation = self.expectation(description: "Success response triggered")
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = BasicRequest(method: .get, path: "/posts")
        
        dispatcher.make(request).then({ response -> SuccessResponse<[Post]> in
            // [weak self] not needed as `self` is not called
            let posts = try response.decode([Post].self)
            return SuccessResponse<[Post]>(data: posts, response: response)
        }).success({ [weak self] response in
            // [weak self] needed as `self` is called
            self?.show(response.data)
        }).completion({
            // [weak self] needed as `self` is called
            // You can use an optional self directly.
            expectation.fulfill()
        }).send()
        
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testWeakCallbacksStrongReference() {
        let expectation = self.expectation(description: "Success response triggered")
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = BasicRequest(method: .get, path: "/posts")
        
        self.strongPromise = dispatcher.make(request).then({ response in
            // [weak self] not needed as `self` is not called
            let posts = try response.decode([Post].self)
            return SuccessResponse<[Post]>(data: posts, response: response)
        }).success({ [weak self] response in
            // [weak self] needed as `self` is called
            self?.show(response.data)
        }).completion({ [weak self] in
            // [weak self] needed as `self` is called
            self?.strongPromise = nil
            expectation.fulfill()
        })
        
        // Perform other logic, add delay, do whatever you would do that forced you
        // to store a reference to this promise in the first place
        
        self.strongPromise?.send()
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testWeakCallbacksWeakReferenceDealocated() {
        let expectation = self.expectation(description: "Success response should not be triggered")
        expectation.isInverted = true
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = BasicRequest(method: .get, path: "/posts")
        
        self.weakPromise = dispatcher.make(request).completion({
            // [weak self] needed as `self` is not called
            expectation.fulfill()
        })
        
        // Our object is already nil because we have not established a strong reference to it.
        // The `send` method will do nothing. No callback will be triggered.
        
        XCTAssertNil(self.weakPromise)
        self.weakPromise?.send()
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testWeakCallbacksWeakReference() {
        let expectation = self.expectation(description: "Success response triggered")
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = BasicRequest(method: .get, path: "/posts")
        
        self.weakPromise = dispatcher.make(request).completion({
            // Always triggered
            expectation.fulfill()
        }).send()
        
        XCTAssertNotNil(self.weakPromise)
        
        // This promise may still be nil at this point
        // if the request is still pending and no errors
        // are thrown during the request creation process.
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNil(self.weakPromise)
    }
    
    func testReturnedPromiseExample() {
        fetchPost(id: 1).success({ response in
            // Show success
        }).failure({ response in
            // Show error response
        }).error({ error in
            // Show error
        }).send()
    }
    
    func testAdvancedPromise() {
        let expectation = self.expectation(description: "Success response triggered")
        
        // Given
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = BasicRequest(method: .get, path: "/posts/1")
        
        Promise<Post, ServerErrorDetails>(action: { promise in
            // `fulfill` calls the succeed and fail methods.
            // The promise that is fullfilling another promise must be transformed
            // first using `then` and `thenFailure` so that it is of the same type
            // before the fulfill method can be called.
            // You may also succeed or fail the promise manually.
            // `fulfill `calls `start` so there is no need to call it.
            
            dispatcher.make(request).then({ response in
                // `then` callback is triggered only when a successful response comes back.
                return try response.decode(Post.self)
            }).thenFailure({ response in
                // `thenFailure` callback is triggered only when an unsusccessful response comes back.
                return try response.decode(ServerErrorDetails.self)
            }).fulfill(promise)
        }).completion({
            // Perform operation on completion
            expectation.fulfill()
        }).start()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    private func fetchPost(id: Int) -> Promise<SuccessResponse<Data?>, ErrorResponse<Data?>> {
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = BasicRequest(method: .get, path: "/posts/\(id)")
        
        return dispatcher.make(request)
    }
    
    private func show(_ posts: [Post]) {
        print(posts)
    }
}
