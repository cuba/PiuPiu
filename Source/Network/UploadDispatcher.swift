//
//  UploadDispatcher.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-07-04.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation


/// The object that will be making the API call and returning the Future
public protocol UploadDispatcher: class {
    /// Create a future to make an upload request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    /// - Returns: The promise that will send the request.
    func uploadFuture(from urlRequest: URLRequest) -> ResponseFuture<Response<Data?>>
    
    /// Create a future to make an upload request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    ///   - data: The data to send
    /// - Returns: The promise that will send the request.
    func uploadFuture(from urlRequest: URLRequest, data: Data) -> ResponseFuture<Response<Data?>>
}

public extension UploadDispatcher {
    /// Create a future to make a download request.
    ///
    /// - Parameters:
    ///   - callback: A callback that returns the future to send
    /// - Returns: The promise that will send the request.
    func uploadFuture(from callback: @escaping () throws -> URLRequest) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>> { [weak self] future in
            guard let self = self else { return }
            let urlRequest = try callback()
            let nestedFuture = self.uploadFuture(from: urlRequest)
            future.fulfill(with: nestedFuture)
        }
    }
}
