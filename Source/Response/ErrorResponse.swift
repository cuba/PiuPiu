//
//  ErrorResponse.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-03-31.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A failed response object. This is retuned when the response is not a 2xx response.
public struct ErrorResponse<T>: ResponseInterface {
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
    
    /// Create an error response object from another response object of any other type.
    ///
    /// - Parameters:
    ///   - data: The data object to return.
    ///   - response: The response to extract `httpResponse`, `urlRequest` and `statusCode` from.
    ///   - error: The error to associate this error response with.
    public init<U: ResponseInterface>(data: T, response: U, error: ResponseError) {
        self.data = data
        self.error = error
        self.httpResponse = response.httpResponse
        self.urlRequest = response.urlRequest
        self.statusCode = response.statusCode
    }
    
    /// Create an error response object from another response object of any other type.
    ///
    /// - Parameters:
    ///   - data: The data object to return.
    ///   - response: The response to extract `httpResponse`, `urlRequest`, `statusCode` and `error` from.
    ///   - error: The error to associate this error response with.
    public init<U>(data: T, response: ErrorResponse<U>) {
        self.data = data
        self.error = response.error
        self.httpResponse = response.httpResponse
        self.urlRequest = response.urlRequest
        self.statusCode = response.statusCode
    }
}
