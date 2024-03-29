//
//  ResponseInterface.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-02-21.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A successful response object. This is retuned when there is any 2xx response.
public struct Response<Body>: ResponseInterface {
    /// The data object that is attached to this response as specified by the user
    public let data: Body
    
    /// The `URLRequest` that is returned on a successful response.
    /// **Note**: successful responses includes all responses incuding ones with `5xx` status codes
    public let urlResponse: URLResponse
    
    /// The original `URLRequest` that was used to create the request.
    public let urlRequest: URLRequest
    
    /// Create a successful response object.
    ///
    /// - Parameters:
    ///   - data: The data object to return.
    ///   - urlRequest: The `URLRequest` that is returned.
    ///   - urlResponse: The original `URLResponse` that was created.
    public init(data: Body, urlRequest: URLRequest, urlResponse: URLResponse) {
        self.data = data
        self.urlResponse = urlResponse
        self.urlRequest = urlRequest
    }
    
    /// Create a successful response object.
    ///
    /// - Parameters:
    ///   - response: the original response
    ///   - data: The data object to return
    public init<R: ResponseInterface>(response: R, data: Body) {
        self.data = data
        self.urlResponse = response.urlResponse
        self.urlRequest = response.urlRequest
    }
}

extension Response where Body == Data? {
    /// Attempts to cast the `URLRequest` to a `HTTPURLResponse` and returns a wrapping `HTTPResponse` object if succesful.
    /// - Returns: The `HTTPResponse` object which wraps the `HTTPURLResponse`
    /// - throws: `ResponseError.notHTTPResponse`
    public func makeHTTPResponse() throws -> HTTPResponse<Body> {
        return try HTTPResponse(response: self, data: data)
    }
    
    /// Attempt to decode the response to a response containing a  `Decodable` object
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
    /// - throws: An error if any value throws an error during decoding.
    public func decoded<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> Response<D> {
        let decoded = try self.decode(type, using: decoder)
        return Response<D>(response: self, data: decoded)
    }
    
    /// Attempt to decode the response to a response containing a `Decodable` object
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
    /// - throws: An error if any value throws an error during decoding.
    @available(*, deprecated, renamed: "decoded")
    public func decodedResponse<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> Response<D> {
        return try decoded(type, using: decoder)
    }
    
    /// Attempt to decode the response to a response containing a `Decodable` object
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - throws: An error if any value throws an error during decoding.
    public func decodedIfPresent<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> Response<D?> {
        let decoded = try self.decodeIfPresent(type, using: decoder)
        return Response<D?>(response: self, data: decoded)
    }
    
    /// Attempt to decode the response to a response containing a `Decodable` object
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - throws: An error if any value throws an error during decoding.
    @available(*, deprecated, renamed: "decodedIfPresent")
    public func decodedResponseIfPresent<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> Response<D?> {
        return try decodedIfPresent(type, using: decoder)
    }
}
