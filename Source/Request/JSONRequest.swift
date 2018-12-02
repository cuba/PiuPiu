//
//  JSONRequest.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2018-12-02.
//  Copyright © 2018 Jacob Sikorski. All rights reserved.
//

import Foundation
import Alamofire

public struct JSONRequest: Request {
    public let parameterEncoding: ParameterEncoding = JSONEncoding.default
    
    public var method: HTTPMethod
    public var path:   String
    public var queryItems: [URLQueryItem]?
    public var parameters: [String: Any]?
    public var headers: [String: String]?
    
    public init(method: HTTPMethod, path: String, queryItems: [URLQueryItem]? = nil, parameters: [String: Any]? = nil, headers: [String: String]? = nil) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.parameters = parameters
        self.headers = headers
    }
}
