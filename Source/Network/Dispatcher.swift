//
//  Dispatcher.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-03-31.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// The object that will be making the API call and returning the Future
public protocol Dispatcher {
    
    /// Make a promise to send a future network call.
    ///
    /// - Parameters:
    ///   - request: The request to send.
    /// - Returns: A future network call that is made when `start()` or `send()` is called.
    func future(from request: Request) -> ResponseFuture<Response<Data?>>
}

public extension Dispatcher {
    
    /// Make a promise to send the network call.
    ///
    /// - Parameters:
    ///   - callback: A callback that constructs the Request object.
    /// - Returns: A promise to make the network call.
    func future(from callback: @escaping () throws -> Request) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { future in
            let request = try callback()
            let requestPromise = self.future(from: request)
            future.fulfill(with: requestPromise)
        }
    }
}
