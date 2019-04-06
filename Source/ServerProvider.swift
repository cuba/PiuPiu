//
//  ServerProvider.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

/// The object that returns the server host or base url
public protocol ServerProvider: class {
    var baseURL: URL { get }
}

/// Extensions used by NetworkDispatcher
public extension ServerProvider {
    
    /// Attempt to construct a URL from the request.
    ///
    /// - Parameter request: The request that will be sent.
    /// - Returns: A url to which the request will be sent.
    /// - Throws: Any errors when trying to create the url.
    func url(from request: Request) throws -> URL {
        
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = request.queryItems
        urlComponents?.path = request.path
        
        if let url = urlComponents?.url {
            return url
        } else {
            throw URLError(.badURL)
        }
    }
    
    /// Attempt to convert the request to a URLRequest.
    ///
    /// - Parameter request: The request that will be converted
    /// - Returns: The created URLRequest
    /// - Throws: A RequstError object
    func urlRequest(from request: Request) throws -> URLRequest {
        do {
            let url = try self.url(from: request)
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
