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
    /// - Parameter request: The request to send.
    /// - Returns: The promise that will send the request.
    open func future(from request: Request, on queue: DispatchQueue = .main) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { [weak self] promise in
            guard let self = self else { return }
            
            guard let serverProvider = self.serverProvider else {
                throw RequestError.missingServerProvider
            }
            
            let urlRequest = try serverProvider.urlRequest(from: request)
            let session = URLSession(configuration: self.configuration)
            
            let task = session.dataTask(with: urlRequest) { (data: Data?, urlResponse: URLResponse?, error: Error?) in
                // Ensure there is a http response
                guard let httpResponse = urlResponse as? HTTPURLResponse else {
                    let error = ResponseError.unknown(cause: error)
                    
                    queue.async {
                        promise.fail(with: error)
                    }
                    
                    return
                }
                
                // Create the response
                let statusCode = StatusCode(rawValue: httpResponse.statusCode)
                let responseError = statusCode.makeError(cause: error)
                let response = Response(data: data, httpResponse: httpResponse, urlRequest: urlRequest, statusCode: statusCode, error: responseError)
                
                queue.async {
                    promise.succeed(with: response)
                }
            }
            
            task.resume()
        }
    }
}
