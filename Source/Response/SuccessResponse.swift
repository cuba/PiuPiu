//
//  SuccessResponse.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2019-03-31.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A successful response object. This is retuned when there is any 2xx response.
public struct SuccessResponse<T>: ResponseInterface {
    public let data: T
    public let httpResponse: HTTPURLResponse
    public let urlRequest: URLRequest
    public let statusCode: StatusCode
    
    /// Create a successful response object.
    ///
    /// - Parameters:
    ///   - data: The data object to return.
    ///   - httpResponse: The `HTTPURLresponse` that is returned.
    ///   - urlRequest: The original `URLRequest` that was created.
    ///   - statusCode: The status code enum that is returned.
    public init(data: T, httpResponse: HTTPURLResponse, urlRequest: URLRequest, statusCode: StatusCode) {
        self.data = data
        self.httpResponse = httpResponse
        self.urlRequest = urlRequest
        self.statusCode = statusCode
    }
    
    public init<U: ResponseInterface>(data: T, response: U) {
        self.data = data
        self.httpResponse = response.httpResponse
        self.urlRequest = response.urlRequest
        self.statusCode = response.statusCode
    }
}
