//
//  ServerProvider.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

public protocol ServerProvider: class {
    var baseURL: URL { get }
}

public extension ServerProvider {
    public func url(from request: Request) throws -> URL {
        
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = request.queryItems
        urlComponents?.path = request.path
        
        if let url = try urlComponents?.asURL() {
            return url
        } else {
            throw URLError(.badURL)
        }
    }
    
    public func urlRequest(from request: Request) throws -> URLRequest {
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
