//
//  DataDispatcher.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-07-03.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// The object that will be making the API call and returning the Future
public protocol DataDispatcher: class {
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    /// - Returns: The promise that will send the request.
    func dataFuture(from urlRequest: URLRequest) -> ResponseFuture<Response<Data?>>
}

public extension DataDispatcher {
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - callback: A callback that returns the future to send
    /// - Returns: The promise that will send the request.
    func dataFuture(from callback: @escaping () throws -> URLRequest?) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>> { [weak self] future in
            guard let self = self else { return }
            guard let urlRequest = try callback() else {
                future.cancel()
                return
            }
            
            let nestedFuture = self.dataFuture(from: urlRequest)
            future.fulfill(with: nestedFuture)
        }
    }
}
