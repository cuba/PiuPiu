//
//  HTTPResponse.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-03-31.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A successful response object. This is retuned when there is any 2xx response.
public struct HTTPResponse<Body>: ResponseInterface {
    public let data: Body
    public var urlRequest: URLRequest
    public let httpResponse: HTTPURLResponse
    
    public var urlResponse: URLResponse {
        return httpResponse
    }
    
    /// Returns a status code in as an enum
    public var statusCode: StatusCode {
        return StatusCode(rawValue: httpResponse.statusCode)
    }
    
    /// Convenience method for `statusCode.httpError`
    public var httpError: HTTPError? {
        return statusCode.httpError
    }
    
    /// Create a successful response object.
    ///
    /// - Parameters:
    ///   - data: The data object to return.
    ///   - urlRequest: The original `URLRequest` that was created.   
    ///   - httpResponse: The `HTTPURLresponse` that is returned.
    public init(data: Body, urlRequest: URLRequest, httpResponse: HTTPURLResponse) {
        self.data = data
        self.urlRequest = urlRequest
        self.httpResponse = httpResponse
    }
    
    /// Create a successful response object.
    ///
    /// - Parameters:
    ///   - response: the original response
    ///   - data: The data object to return
    /// - throws: `ResponseError.notHTTPResponse`
    public init<R: ResponseInterface>(response: R, data: Body) throws {
        // Ensure there is a http response
        guard let httpResponse = response.urlResponse as? HTTPURLResponse else {
            throw ResponseError.notHTTPResponse
        }
        
        self.data = data
        self.urlRequest = response.urlRequest
        self.httpResponse = httpResponse
    }
}

extension HTTPResponse where Body == Data? {
    /// Attempt to Decode the response to a response containing a decodable object
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
    /// - throws: An error if any value throws an error during decoding.
    public func decoded<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> HTTPResponse<D> {
        let decoded = try self.decode(type, using: decoder)
        return try HTTPResponse<D>(response: self, data: decoded)
    }
    
    /// Attempt to Decode the response to a response containing a decodable object
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
    /// - throws: An error if any value throws an error during decoding.
    @available(*, deprecated, renamed: "decoded")
    public func decodedResponse<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> HTTPResponse<D> {
        return try decoded(type, using: decoder)
    }
    
    /// Attempt to Decode the response to a response containing a decodable object
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - throws: An error if any value throws an error during decoding.
    public func decodedIfPresent<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> HTTPResponse<D?> {
        let decoded = try self.decodeIfPresent(type, using: decoder)
        return try HTTPResponse<D?>(response: self, data: decoded)
    }
    
    /// Attempt to Decode the response to a response containing a decodable object
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - throws: An error if any value throws an error during decoding.
    @available(*, deprecated, renamed: "decodedIfPresent")
    public func decodedResponseIfPresent<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> HTTPResponse<D?> {
        return try decodedIfPresent(type, using: decoder)
    }
}
