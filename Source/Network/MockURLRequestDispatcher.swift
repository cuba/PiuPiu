//
//  MockURLRequestDispatcher.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-07.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A mock dispatcher that does not actually make any network calls.
open class MockURLRequestDispatcher: DataDispatcher, DownloadDispatcher, UploadDispatcher {
    public typealias ResponseCallback = (URLRequest) throws -> Response<Data?>
    open var delay: TimeInterval = 0
    
    open var callback: ResponseCallback?
    
    /// Initialize this object with some mock data.
    ///
    /// - Parameters:
    ///   - mockStatusCode: The status code to return
    ///   - mockHeaders: The headers that will be returned
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
        return ResponseFuture<Response<Data?>>() { [weak self] future in
            guard let self = self else { return }
            
            guard let response = try self.callback?(urlRequest) else {
                throw ResponseError.unknown
            }
            
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delay) {
                future.update(progress: 1)
                future.succeed(with: response)
            }
        }
    }
    
    /// Create a future to make a download request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    /// - Returns: The promise that will send the request.
    open func downloadFuture(from urlRequest: URLRequest) -> ResponseFuture<Data?> {
        return ResponseFuture<Data?>() { [weak self] future in
            guard let self = self else { return }
            
            guard let response = try self.callback?(urlRequest) else {
                throw ResponseError.unknown
            }
            
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delay) {
                future.update(progress: 1)
                future.succeed(with: response.data)
            }
        }
    }
    
    /// Create a future to make a upload request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    /// - Returns: The promise that will send the request.
    open func uploadFuture(from urlRequest: URLRequest) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { [weak self] future in
            guard let self = self else { return }
            
            guard let response = try self.callback?(urlRequest) else {
                throw ResponseError.unknown
            }
            
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delay) {
                future.update(progress: 1)
                future.succeed(with: response)
            }
        }
    }
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    ///   - data: The data to send
    /// - Returns: The promise that will send the request.
    open func uploadFuture(from urlRequest: URLRequest, data: Data) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { [weak self] future in
            guard let self = self else { return }
            
            guard let response = try self.callback?(urlRequest) else {
                throw ResponseError.unknown
            }
            
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delay) {
                future.update(progress: 1)
                future.succeed(with: response)
            }
        }
    }
}
