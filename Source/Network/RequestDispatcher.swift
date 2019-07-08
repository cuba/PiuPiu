//
//  RequestDispatcher.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

/// The class that will be making the API call.
open class RequestDispatcher: Dispatcher {
    public weak var serverProvider: ServerProvider?
    public let dataDispatcher: DataDispatcher
    
    /// Initialize this `Dispatcher` with a `ServerProvider` and a `URLSessionConfiguration`.
    ///
    /// - Parameters:
    ///   - serverProvider: The server provider that will give the dispatcher the `baseURL`.
    ///   - configuration: The configuration that will be used to create the `URLSession`.
    public convenience init(serverProvider: ServerProvider, configuration: URLSessionConfiguration = .default) {
        self.init(serverProvider: serverProvider, dataDispatcher: URLRequestDispatcher(configuration: configuration))
    }
    
    /// Initialize this `Dispatcher` with a `ServerProvider` and a `DataDispatcher`.
    ///
    /// - Parameters:
    ///   - serverProvider: The server provider that will give the dispatcher the `baseURL`.
    ///   - dispatcher: The dispatcher that will be used to make the url request.
    public init(serverProvider: ServerProvider, dataDispatcher: DataDispatcher) {
        self.serverProvider = serverProvider
        self.dataDispatcher = dataDispatcher
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
            let newFuture = self.dataDispatcher.dataFuture(from: urlRequest)
            future.fulfill(with: newFuture)
        }
    }
}
