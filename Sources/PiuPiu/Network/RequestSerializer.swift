//
//  RequestSerializer.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-16.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// This class wraps the dispatcher and users a `Request` protocol to send the request. This way you don't have to manually create the url request when using the same type of request.
public class RequestSerializer {
    public var dispatcher: DataDispatcher
    public weak var serverProvider: ServerProvider?
    
    
    /// Initialize this serializer with a dispatcher and server provider
    /// - Parameters:
    ///   - dispatcher: The dispatcher to send the calls with
    ///   - serverProvider: The server provider that provides the base URL. Note: The reference to this is weak so you need to hold on to it yourself
    public init(dispatcher: DataDispatcher, serverProvider: ServerProvider) {
        self.dispatcher = dispatcher
        self.serverProvider = serverProvider
    }
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    /// - Returns: The promise that will send the request.
    public func dataFuture(from request: Request) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>> { [weak self] future in
            guard let self = self else { return }
            
            guard let serverProvider = self.serverProvider else {
                throw RequestError.missingServerProvider
            }
            
            guard let baseUrl = serverProvider.baseURL else {
                throw RequestError.missingURL
            }
            
            let urlRequest = try request.urlRequest(withBaseURL: baseUrl)
            let newFuture = self.dispatcher.dataFuture(from: urlRequest)
            future.fulfill(by: newFuture)
        }
    }
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - callback: A callback that returns the future to send
    /// - Returns: The promise that will send the request.
    public func dataFuture(from callback: @escaping () throws -> Request?) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>> { [weak self] future in
            guard let self = self else { return }
            guard let request = try callback() else {
                future.cancel()
                return
            }
            
            let nestedFuture = self.dataFuture(from: request)
            future.fulfill(by: nestedFuture)
        }
    }
}
