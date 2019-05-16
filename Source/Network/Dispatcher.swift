//
//  Dispatcher.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-03-31.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public typealias ResponsePromise<T, E> = Promise<SuccessResponse<T>, ErrorResponse<E>>

/// The object that will be making the API call and returning the Future
public protocol Dispatcher {
    
    /// Make a promise to send a future network call.
    ///
    /// - Parameters:
    ///   - request: The request to send.
    ///   - queue: The DispatchQueue on which to return the results on.
    /// - Returns: A future network call that is made when `start()` or `send()` is called.
    func future(from request: Request, on queue: DispatchQueue) -> ResponseFuture<Response<Data?>>
}

public extension Dispatcher {
    
    /// Make a promise to send the network call.
    ///
    /// - Parameter callback: A callback that constructs the Request object.
    /// - Returns: A promise to make the network call.
    @available(*, deprecated, renamed: "makeRequest(from:)")
    func make(from callback: @escaping () throws -> Request) -> ResponsePromise<Data?, Data?> {
        return makeRequest(from: callback)
    }
    
    /// Make a promise to send the request.
    ///
    /// - Parameter request: The request to send.
    /// - Returns: The promise that will send the request.
    @available(*, deprecated, renamed: "promise(from:)")
    func make(_ request: Request) -> ResponsePromise<Data?, Data?> {
        return self.promise(from: request)
    }
    
    /// Make a promise to send the request.
    ///
    /// - Parameter request: The request to send.
    /// - Returns: The promise that will send the request.
    func promise(from request: Request) -> ResponsePromise<Data?, Data?> {
        return Promise<SuccessResponse<Data?>, ErrorResponse<Data?>>() { promise in
            self.future(from: request).response({ response in
                if let responseError = response.error {
                    let errorResponse = ErrorResponse(data: response.data, httpResponse: response.httpResponse, urlRequest: response.urlRequest, statusCode: response.statusCode, error: responseError)
                    promise.fail(with: errorResponse)
                } else {
                    let successResponse = SuccessResponse(data: response.data, httpResponse: response.httpResponse, urlRequest: response.urlRequest, statusCode: response.statusCode)
                    promise.succeed(with: successResponse)
                }
            }).error({ error in
                promise.catch(error)
            }).send()
        }
    }
    
    /// Make a promise to send the network call.
    ///
    /// - Parameter callback: A callback that constructs the Request object.
    /// - Returns: A promise to make the network call.
    @available(*, deprecated, renamed: "promise(from:)")
    func makeRequest(from callback: @escaping () throws -> Request) -> ResponsePromise<Data?, Data?> {
        return promise(from: callback)
    }
    
    /// Make a promise to send the network call.
    ///
    /// - Parameter callback: A callback that constructs the Request object.
    /// - Returns: A promise to make the network call.
    func promise(from callback: @escaping () throws -> Request) -> ResponsePromise<Data?, Data?> {
        return Promise<SuccessResponse<Data?>, ErrorResponse<Data?>>() { promise in
            let request = try callback()
            let requestPromise = self.promise(from: request)
            requestPromise.fulfill(promise)
        }
    }
    
    func future(from request: Request) -> ResponseFuture<Response<Data?>> {
        return self.future(from: request, on: .main)
    }
    
    /// Make a promise to send the network call.
    ///
    /// - Parameter callback: A callback that constructs the Request object.
    /// - Returns: A promise to make the network call.
    func future(from callback: @escaping () throws -> Request, on queue: DispatchQueue = .main) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { promise in
            let request = try callback()
            let requestPromise = self.future(from: request, on: queue)
            promise.fulfill(with: requestPromise)
        }
    }
}
