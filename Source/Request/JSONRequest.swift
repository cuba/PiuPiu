//
//  JSONRequest.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2018-12-02.
//  Copyright © 2018 Jacob Sikorski. All rights reserved.
//

import Foundation
import Alamofire
import MapCodableKit

public struct JSONRequest: Request {
    public let parameterEncoding: ParameterEncoding = JSONEncoding.default
    
    public var method: HTTPMethod
    public var path:   String
    public var queryItems: [URLQueryItem]?
    public var body: [String: Any]?
    public var headers: [String: String]?
    
    public init(method: HTTPMethod, path: String, queryItems: [URLQueryItem]? = nil, body: [String: Any]? = nil, headers: [String: String]? = nil) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.body = body
        self.headers = headers
    }
    
    public init<T: MapEncodable>(method: HTTPMethod, path: String, queryItems: [URLQueryItem]? = nil, body: T, headers: [String: String]? = nil) throws {
        self.init(method: method, path: path, queryItems: queryItems, headers: headers)
        self.body = [:]
        
        // TODO: Alamofire uses [String: Any] so we can't send nil values?
        // Need to figure this out or drop alamofire (its way too big anyway)
        for (key, value) in try body.json() {
            // TODO: @JS Remove empty sub array values?
            guard let value = value else { continue }
            self.body?[key] = value
        }
    }
}
