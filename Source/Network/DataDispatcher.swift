//
//  DataDispatcher.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-06-30.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

open class DataDispatcher {
    private var session: ResponseFutureSession
    
    /// Initialize this `Dispatcher` with `URLSessionConfiguration`.
    ///
    /// - Parameters:
    ///   - configuration: The configuration that will be used to create the `URLSession`.
    public init(configuration: URLSessionConfiguration = .default) {
        session = ResponseFutureSession(configuration: configuration)
    }
    
    deinit {
        session.finishTasksAndInvalidate()
        
        #if DEBUG
        print("DEINIT - DataDispatcher")
        #endif
    }
    
    open func invalidateAndCancel() {
        session.invalidateAndCancel()
    }
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - callback: A callback that returns the future to send
    /// - Returns: The promise that will send the request.
    open func dataFuture(from callback: @escaping () throws -> URLRequest) -> ResponseFuture<Response<Data?>> {
        return session.dataFuture(from: callback)
    }
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    /// - Returns: The promise that will send the request.
    open func dataFuture(from urlRequest: URLRequest) -> ResponseFuture<Response<Data?>> {
        return session.dataFuture(from: urlRequest)
    }
    
    /// Create a future to make a download request.
    ///
    /// - Parameters:
    ///   - callback: A callback that returns the future to send
    /// - Returns: The promise that will send the request.
    open func downloadFuture(from callback: @escaping () throws -> URLRequest) -> ResponseFuture<Data?> {
        return session.downloadFuture(from: callback)
    }
    
    /// Create a future to make a download request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    /// - Returns: The promise that will send the request.
    open func downloadFuture(from urlRequest: URLRequest) -> ResponseFuture<Data?> {
        return session.downloadFuture(from: urlRequest)
    }
}
