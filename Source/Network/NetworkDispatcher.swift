//
//  NetworkDispatcher.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

/// The class that will be making the API call.
open class NetworkDispatcher: Dispatcher {
    public weak var serverProvider: ServerProvider?
    public let dispatcher: URLRequestDispatcher
    
    /// Initialize this `Dispatcher` with a `ServerProvider` and a `URLSessionConfiguration`.
    ///
    /// - Parameters:
    ///   - serverProvider: The server provider that will give the dispatcher the `baseURL`.
    ///   - configuration: The configuration that will be used to create the `URLSession`.
    ///   - delegate: The delegate that will be used for the URLSession.
    public init(serverProvider: ServerProvider, configuration: URLSessionConfiguration = .default) {
        self.serverProvider = serverProvider
        self.dispatcher = URLRequestDispatcher(configuration: configuration)
    }
    
    /// Make a promise to send the request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    ///   - queue: The queue on which to syncronize the result to
    /// - Returns: The promise that will send the request.
    open func future(from request: Request) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { [weak self] future in
            guard let self = self else { return }
            
            guard let serverProvider = self.serverProvider else {
                throw RequestError.missingServerProvider
            }
            
            let urlRequest = try serverProvider.urlRequest(from: request)
            let newFuture = self.dispatcher.dataFuture(from: urlRequest)
            future.fulfill(with: newFuture)
        }
    }
}
