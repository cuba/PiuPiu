//
//  DownloadDispatcher.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-07-03.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// The object that will be making the API call and returning the Future
public protocol DownloadDispatcher: class {
    /// Create a future to make a download request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    /// - Returns: The promise that will send the request.
    func downloadFuture(from urlRequest: URLRequest) -> ResponseFuture<URL>
}

public extension DownloadDispatcher {
    /// Create a future to make a download request.
    ///
    /// - Parameters:
    ///   - callback: A callback that returns the future to send. Returning nil will cancel the request.
    /// - Returns: The promise that will send the request.
    func downloadFuture(from callback: @escaping () throws -> URLRequest?) -> ResponseFuture<URL> {
        return ResponseFuture<URL> { [weak self] future in
            guard let self = self else { return }
            guard let urlRequest = try callback() else {
                future.cancel()
                return
            }
            
            let nestedFuture = self.downloadFuture(from: urlRequest)
            future.fulfill(with: nestedFuture)
        }
    }
}
