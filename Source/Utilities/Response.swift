//
//  Response.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2019-02-21.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// The protocol wrapping the response object.
public protocol Response {
    associatedtype T
    
    var data: T { get }
    var httpResponse: HTTPURLResponse { get }
    var urlRequest: URLRequest { get }
    var statusCode: StatusCode { get }
}

/// A successful response object. This is retuned when there is any 2xx response.
public struct SuccessResponse<T>: Response {
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
    
    init<U: Response>(data: T, response: U) {
        self.data = data
        self.httpResponse = response.httpResponse
        self.urlRequest = response.urlRequest
        self.statusCode = response.statusCode
    }
}

/// A failed response object. This is retuned when the response is not a 2xx response.
public struct ErrorResponse<T>: Response {
    public let data: T
    public let httpResponse: HTTPURLResponse
    public let urlRequest: URLRequest
    public let statusCode: StatusCode
    public let error: ResponseError
    
    /// Create a successful response object.
    ///
    /// - Parameters:
    ///   - data: The data object to return.
    ///   - httpResponse: The `HTTPURLresponse` that is returned.
    ///   - urlRequest: The original `URLRequest` that was created.
    ///   - statusCode: The status code enum that is returned.
    ///   - error: The error that is returned.
    public init(data: T, httpResponse: HTTPURLResponse, urlRequest: URLRequest, statusCode: StatusCode, error: ResponseError) {
        self.data = data
        self.httpResponse = httpResponse
        self.urlRequest = urlRequest
        self.statusCode = statusCode
        self.error = error
    }
    
    init<U: Response>(data: T, error: ResponseError, response: U) {
        self.data = data
        self.error = error
        self.httpResponse = response.httpResponse
        self.urlRequest = response.urlRequest
        self.statusCode = response.statusCode
    }
}
