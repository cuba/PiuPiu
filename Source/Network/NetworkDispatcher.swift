//
//  NetworkDispatcher.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

/// The class that will be making the API call.
open class NetworkDispatcher: Dispatcher {
    
    public var configuration: URLSessionConfiguration
    public weak var serverProvider: ServerProvider?
    
    /// Initialize this `Dispatcher` with a `ServerProvider` and a `URLSessionConfiguration`.
    ///
    /// - Parameters:
    ///   - serverProvider: The server provider that will give the dispatcher the `baseURL`.
    ///   - configuration: The configuration that will be used to create the `URLSession`.
    ///   - delegate: The delegate that will be used for the URLSession.
    public init(serverProvider: ServerProvider, configuration: URLSessionConfiguration = .default) {
        self.serverProvider = serverProvider
        self.configuration = configuration
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
            let session = URLSession(configuration: self.configuration)
            
            let task = session.dataTask(with: urlRequest) { (data: Data?, urlResponse: URLResponse?, error: Error?) in
                // Check basic error first
                if let error = error {
                    DispatchQueue.main.async {
                        future.fail(with: error)
                    }
                    
                    return
                }
                
                // Ensure there is a http response
                guard let httpResponse = urlResponse as? HTTPURLResponse else {
                    let error = ResponseError.unknown
                    
                    DispatchQueue.main.async {
                        future.fail(with: error)
                    }
                    
                    return
                }
                
                // Create the response
                let statusCode = StatusCode(rawValue: httpResponse.statusCode)
                let responseError = statusCode.makeError()
                let response = Response(data: data, httpResponse: httpResponse, urlRequest: urlRequest, statusCode: statusCode, error: responseError)
                
                DispatchQueue.main.async {
                    future.update(progress: 1)
                    future.succeed(with: response)
                }
            }
            
            task.resume()
        }
    }
}
