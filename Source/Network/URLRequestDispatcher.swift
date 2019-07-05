//
//  URLRequestDispatcher.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-06-30.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

open class URLRequestDispatcher: DataDispatcher, DownloadDispatcher, UploadDispatcher {
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
        print("DEINIT - URLRequestDispatcher")
        #endif
    }
    
    open func invalidateAndCancel() {
        session.invalidateAndCancel()
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
    ///   - request: The request to send
    /// - Returns: The promise that will send the request.
    open func downloadFuture(from urlRequest: URLRequest) -> ResponseFuture<Data?> {
        return session.downloadFuture(from: urlRequest)
    }
    
    /// Create a future to make a upload request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    /// - Returns: The promise that will send the request.
    open func uploadFuture(from urlRequest: URLRequest) -> ResponseFuture<Response<Data?>> {
        return session.uploadFuture(from: urlRequest)
    }
    
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    ///   - data: The data to send
    /// - Returns: The promise that will send the request.
    open func uploadFuture(from urlRequest: URLRequest, data: Data) -> ResponseFuture<Response<Data?>> {
        return session.uploadFuture(from: urlRequest, data: data)
    }
}
