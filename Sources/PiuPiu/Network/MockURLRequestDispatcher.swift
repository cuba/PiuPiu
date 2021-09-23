//
//  MockURLRequestDispatcher.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-07.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A mock dispatcher that does not actually make any network calls. Useful for tests or for mocking data.
open class MockURLRequestDispatcher: DataDispatcher, UploadDispatcher {
    public typealias ResponseCallback = (URLRequest) throws -> Response<Data?>
    /// Add a delay to the response to simulate slower load times. Its a good idea to keep this short on tests
    open var delay: TimeInterval = 0
    
    /// The callback that is triggered which returns the appropriate response given a `URLRequest`
    open var callback: ResponseCallback?
    
    /// Initialize this object with some mock data.
    ///
    /// - Parameters:
    ///   - delay: Add a delay to the response to simulate slower load times. Its a good idea to keep this short on tests
    ///   - callback: The callback that is triggered which returns the appropriate response given a `URLRequest`
    public init(delay: TimeInterval = 0, callback: @escaping ResponseCallback) {
        self.callback = callback
        self.delay = delay
    }
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - urlRequest: The request to send
    /// - Returns: The promise that will send the request.
    open func dataFuture(from urlRequest: URLRequest) -> ResponseFuture<Response<Data?>> {
        return makeFuture(from: urlRequest)
    }
    
    /// Create a future to make a upload request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    /// - Returns: The promise that will send the request.
    open func uploadFuture(from urlRequest: URLRequest) -> ResponseFuture<Response<Data?>> {
        return makeFuture(from: urlRequest)
    }
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    ///   - data: The data to send
    /// - Returns: The promise that will send the request.
    open func uploadFuture(from urlRequest: URLRequest, with data: Data) -> ResponseFuture<Response<Data?>> {
        return makeFuture(from: urlRequest)
    }
    
    private func makeFuture(from urlRequest: URLRequest) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { [weak self] future in
            guard let self = self else { return }
            let task = URLSessionDataTask()
            future.update(with: task)
            
            guard let response = try self.callback?(urlRequest) else {
                throw ResponseError.noResponse
            }
            
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delay) {
                future.update(with: task)
                future.succeed(with: response)
            }
        }
    }
}
