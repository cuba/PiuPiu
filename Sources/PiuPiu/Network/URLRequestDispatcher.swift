//
//  URLRequestDispatcher.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-06-30.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A protocol that allows to adapt or handle a response
public protocol URLResponseAdapter: AnyObject {
    /// Adapt a response or perform some operations before returning the result.
    /// - Returns: An adapted response
    func adapt(urlResponse: URLResponse, for urlRequest: URLRequest, with callback: @escaping (URLResponse) throws -> Void) throws
}

/// A protocol that allows to adapt or handle a request
public protocol URLRequestAdapter: AnyObject {
    /// Adapt a request or perform some operations before returning the result
    /// - Returns: An adapted request
    func adapt(urlRequest: URLRequest, with callback: @escaping (URLRequest) throws -> Void) throws
}

/// This is a convenience class for making URL requests in the form of futures.
/// It implements the `DataDispatcher`, `DownloadDispatcher`, `UploadDispatcher` protocols.
/// This class can be used in almost any setting.
open class URLRequestDispatcher: DataDispatcher, DownloadDispatcher, UploadDispatcher {
    private var session: ResponseFutureSession
    private weak var responseAdapter: URLResponseAdapter?
    private weak var requestAdapter: URLRequestAdapter?
    
    /// Initialize this `Dispatcher` with `URLSessionConfiguration`.
    ///
    /// - Parameters:
    ///   - configuration: The configuration that will be used to create the `URLSession`.
    ///   - requestAdapter: An adapter that allows you to change the properties of the request or perform other operations before doing the request
    ///   - responseAdapter: An adapter that allows you to change the properties of the response or perform other operations
    public init(
        configuration: URLSessionConfiguration = .default,
        requestAdapter: URLRequestAdapter? = nil,
        responseAdapter: URLResponseAdapter? = nil
    ) {
        self.session = ResponseFutureSession(configuration: configuration)
        self.requestAdapter = requestAdapter
        self.responseAdapter = responseAdapter
    }
    
    deinit {
        finishTasksAndInvalidate()
        
        #if DEBUG
        print("DEINIT - URLRequestDispatcher")
        #endif
    }

    /// This finishes all the tasks on the session and invalidates them.
    /// Essentially it calls `finishTasksAndInvalidate` on the `URLSession`
    open func finishTasksAndInvalidate() {
        session.finishTasksAndInvalidate()
    }

    /// This invalidates all the tasks on the session and cancels them.
    /// Essentially it calls `invalidateAndCancel` on the `URLSession`
    open func invalidateAndCancel() {
        session.invalidateAndCancel()
    }
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - urlRequest: The request to send
    /// - Returns: The promise that will send the request.
    open func dataFuture(from urlRequest: URLRequest) -> ResponseFuture<Response<Data?>> {
        let future = adaptedRequestFuture(from: urlRequest) { [weak self] adaptedRequest in
            self?.session.dataFuture(from: urlRequest)
        }

        return adaptResponseFuture(from: urlRequest, and: future)
    }
    
    /// Create a future to make a download request.
    ///
    /// - Parameters:
    ///   - urlRequest: The request to send
    /// - Returns: The promise that will send the request.
    open func downloadFuture(from urlRequest: URLRequest, to destination: URL) -> ResponseFuture<Response<URL>> {
        let future = adaptedRequestFuture(from: urlRequest) { [weak self] adaptedRequest in
            self?.session.downloadFuture(from: urlRequest, to: destination)
        }

        return adaptResponseFuture(from: urlRequest, and: future)
    }
    
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - urlRequest: The request to send
    ///   - data: The data to send
    /// - Returns: The promise that will send the request.
    open func uploadFuture(from urlRequest: URLRequest, with data: Data) -> ResponseFuture<Response<Data?>> {
        let future = adaptedRequestFuture(from: urlRequest) { [weak self] adaptedRequest in
            self?.session.uploadFuture(from: urlRequest, with: data)
        }

        return adaptResponseFuture(from: urlRequest, and: future)
    }

    /// Creates a ResponseFuture given the `callback` and adapts the given `urlRequest` if a `requestAdapter` is attached to this class
    /// If `requestAdapter` is not attached, a wrapped future will still be returned but its result is unchanged.
    private func adaptedRequestFuture<T>(from urlRequest: URLRequest, callback: @escaping (URLRequest) -> ResponseFuture<Response<T>>?) -> ResponseFuture<Response<T>> {
        return ResponseFuture<Response<T>> { [weak self] future in
            if let requestAdapter = self?.requestAdapter {
                try requestAdapter.adapt(urlRequest: urlRequest) { adaptedRequest in
                    callback(adaptedRequest)?.fulfill(future)
                }
            } else {
                callback(urlRequest)?.fulfill(future)
            }
        }
    }

    /// Returns a wrapped future with an adapted `URLResponse` if a `responseAdapter` is attached to this class.
    /// If `responseAdapter` is not attached, a wrapped future will still be returned but its result is unchanged.
    private func adaptResponseFuture<T>(from urlRequest: URLRequest, and responseFuture: ResponseFuture<Response<T>>) -> ResponseFuture<Response<T>> {
        return ResponseFuture<Response<T>> { [weak self] future in
            responseFuture
                .success { [weak self] response in
                    if let adapter = self?.responseAdapter {
                        try adapter.adapt(urlResponse: response.urlResponse, for: urlRequest) { adaptedURLResponse in
                            let adaptedResponse = Response(data: response.data, urlRequest: urlRequest, urlResponse: adaptedURLResponse)
                            future.succeed(with: adaptedResponse)
                        }
                    } else {
                        future.succeed(with: response)
                    }
                }
                .error { error in
                    future.fail(with: error)
                }
                .updated { task in
                    future.update(with: task)
                }
                .start()
        }
    }
}
