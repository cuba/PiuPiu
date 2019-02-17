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
    public var queryItems: [URLQueryItem]
    public var headers: [String: String]
    public var httpBody: Data?
    
    public init(method: HTTPMethod, path: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:]) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.headers = [:]
        
        if method.requiresBody {
            self.headers["Content-Type"] = "application/json"
        }
        
        for (key, value) in headers {
            self.headers[key] = value
        }
    }
    
    public init<T: MapEncodable>(method: HTTPMethod, path: String, queryItems: [URLQueryItem] = [], body: T, headers: [String: String] = [:]) throws {
        self.init(method: method, path: path, queryItems: queryItems, headers: headers)
        self.httpBody = try body.jsonData()
    }
}
