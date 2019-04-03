//
//  Dispatcher.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2019-03-31.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public typealias ResponsePromise<T, E> = Promise<SuccessResponse<T>, ErrorResponse<E>>

/// The object that will be making the API call.
public protocol Dispatcher {
    
    /// Make a promise to send the network call.
    ///
    /// - Parameter callback: A callback that constructs the Request object.
    /// - Returns: A promise to make the network call.
    func make(_ request: Request) -> ResponsePromise<Data?, Data?>
    func future(from request: Request) -> ResponseFuture<Response<Data?>>
}

public extension Dispatcher {
    
    /// Make a promise to send the network call.
    ///
    /// - Parameter callback: A callback that constructs the Request object.
    /// - Returns: A promise to make the network call.
    @available(*, deprecated, renamed: "makeRequest(from:)")
    public func make(from callback: @escaping () throws -> Request) -> ResponsePromise<Data?, Data?> {
        return makeRequest(from: callback)
    }
    
    /// Make a promise to send the request.
    ///
    /// - Parameter request: The request to send.
    /// - Returns: The promise that will send the request.
    public func make(_ request: Request) -> ResponsePromise<Data?, Data?> {
        return Promise<SuccessResponse<Data?>, ErrorResponse<Data?>>() { promise in
            self.future(from: request).response({ response in
                if let error = response.error {
                    let responseError = response.statusCode.makeError(cause: error) ?? ResponseError.unknown(cause: error)
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
    public func makeRequest(from callback: @escaping () throws -> Request) -> ResponsePromise<Data?, Data?> {
        return Promise<SuccessResponse<Data?>, ErrorResponse<Data?>>() { promise in
            let request = try callback()
            let requestPromise = self.make(request)
            requestPromise.fulfill(promise)
        }
    }
    
    /// Make a promise to send the network call.
    ///
    /// - Parameter callback: A callback that constructs the Request object.
    /// - Returns: A promise to make the network call.
    public func future(from callback: @escaping () throws -> Request) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { promise in
            let request = try callback()
            let requestPromise = self.future(from: request)
            requestPromise.fulfill(promise)
        }
    }
}
