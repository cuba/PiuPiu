//
//  NetworkDispatcher.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

// Response types
public typealias SuccessResponse<T> = (data: T, httpResponse: HTTPURLResponse, urlRequest: URLRequest, statusCode: StatusCode)
public typealias ErrorResponse<T> = (data: T, httpResponse: HTTPURLResponse, urlRequest: URLRequest, statusCode: StatusCode, error: BaseNetworkError)

open class NetworkDispatcher {
    public weak var serverProvider: ServerProvider?
    
    public init(serverProvider: ServerProvider) {
        self.serverProvider = serverProvider
    }
    
    open func send(_ request: Request) -> Promise<SuccessResponse<Data?>, ErrorResponse<Data?>> {
        return Promise<SuccessResponse<Data?>, ErrorResponse<Data?>>() { promise in
            guard let serverProvider = self.serverProvider else {
                throw RequestError.missingServerProvider
            }
            
            let urlRequest = try self.urlRequest(from: request, serverProvider: serverProvider)
            
            let task = URLSession.shared.dataTask(with: urlRequest) { (data: Data?, urlResponse: URLResponse?, error: Error?) in
                // Ensure there is a status code (ex: 200)
                guard let response = urlResponse as? HTTPURLResponse else {
                    let error = ResponseError.unknown(cause: error)
                    DispatchQueue.main.async {
                        promise.catch(error)
                    }
                    return
                }
                
                let statusCode = StatusCode(rawValue: response.statusCode)
                
                // Get the status code
                if let responseError = statusCode.error(cause: error) {
                    DispatchQueue.main.async {
                        promise.fail(with: (data, response, urlRequest, statusCode, responseError) )
                    }
                } else {
                    DispatchQueue.main.async {
                        promise.succeed(with: (data, response, urlRequest, statusCode))
                    }
                }
            }
            
            task.resume()
        }
    }
    
    private func urlRequest(from request: Request, serverProvider: ServerProvider) throws -> URLRequest {
        do {
            let url = try serverProvider.url(from: request)
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = request.method.rawValue
            urlRequest.httpBody = request.httpBody
            
            for (key, value) in request.headers {
                urlRequest.addValue(value, forHTTPHeaderField: key)
            }
            
            return urlRequest
        } catch let error {
            throw RequestError.invalidURL(cause: error)
        }
    }
}
