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
  public let body: Body
  public var urlRequest: URLRequest
  public let httpResponse: HTTPURLResponse
  
  public var urlResponse: URLResponse {
    return httpResponse
  }
  
  /// Returns a status code in as an enum
  public var statusCode: UnknowableType<StatusCode> {
    return .init(httpResponse.statusCode)
  }
  
  /// Convenience method for `statusCode.httpError`
  public var httpError: HTTPError? {
    return statusCode.known?.httpError
  }
  
  /// Create a successful response object.
  ///
  /// - Parameters:
  ///   - data: The data object to return.
  ///   - urlRequest: The original `URLRequest` that was created.
  ///   - httpResponse: The `HTTPURLresponse` that is returned.
  public init(body: Body, urlRequest: URLRequest, httpResponse: HTTPURLResponse) {
    self.body = body
    self.urlRequest = urlRequest
    self.httpResponse = httpResponse
  }
  
  /// Create a successful response object.
  ///
  /// - Parameters:
  ///   - response: the original response
  ///   - data: The data object to return
  /// - throws: `ResponseError.notHTTPResponse`
  public init(response: Response<Body>, body: Body) throws {
    // Ensure there is a http response
    guard let httpResponse = response.urlResponse as? HTTPURLResponse else {
      throw ResponseError.notHTTPResponse
    }
    
    self.body = body
    self.urlRequest = response.urlRequest
    self.httpResponse = httpResponse
    }
}

extension HTTPResponse where Body == Data? {
  /// Return a response where the `Body` is not nil
  /// - Returns: The `Response<Data>`
  /// - throws: `ResponseError.notHTTPResponse`
  public func ensureData() throws -> HTTPResponse<Data> {
    return try HTTPResponse<Data>.init(
      body: unwrapData(),
      urlRequest: urlRequest,
      httpResponse: httpResponse
    )
  }
  
  /// Ensures that there are no HTTP errors
  public func ensureValidResponse() throws -> Self {
    if let httpError = self.httpError {
      throw httpError
    }
    
    return self
  }
  
  /// Attempt to transform the response to a response containing a decoded object if body is not nil
  ///
  /// - Parameters:
  ///   - type: The Decodable type to decode
  ///   - decoder: The decoder to use.
  ///   - priority: The async priority to use
  /// - Returns: A response containing the decoded object or nil
  /// - throws: An error if any value throws an error during decoding.
  public func ensureDecodedIfPresent<D: Decodable & Sendable>(
    _ type: D.Type,
    using decoder: JSONDecoder = JSONDecoder(),
    priority: TaskPriority? = nil
  ) async throws -> HTTPResponse<D?> {
    return try await HTTPResponse<D?>.init(
      body: self.decodeAsyncIfPresent(type, using: decoder, priority: priority),
      urlRequest: urlRequest,
      httpResponse: httpResponse
    )
  }
  
  /// Attempt to Decode the response to a response containing a decodable object
  ///
  /// - Parameters:
  ///   - type: The Decodable type to decode
  ///   - decoder: The decoder to use.
  /// - Returns: The decoded object
  /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
  /// - throws: An error if any value throws an error during decoding.
  public func ensureDecoded<D: Decodable & Sendable>(
    _ type: D.Type,
    using decoder: JSONDecoder = JSONDecoder(),
    priority: TaskPriority? = nil
  ) async throws -> HTTPResponse<D> {
    return try await ensureData().ensureDecoded(type, using: decoder)
  }
}

extension HTTPResponse where Body == Data {
  /// Attempt to Decode the response to a response containing a decodable object
  ///
  /// - Parameters:
  ///   - type: The Decodable type to decode
  ///   - decoder: The decoder to use.
  /// - Returns: The decoded object
  /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
  /// - throws: An error if any value throws an error during decoding.
  public func ensureDecoded<D: Decodable & Sendable>(
    _ type: D.Type,
    using decoder: JSONDecoder = JSONDecoder(),
    priority: TaskPriority? = nil
  ) async throws -> HTTPResponse<D> {
    return try await HTTPResponse<D>.init(
      body: self.decodeAsync(type, using: decoder, priority: priority),
      urlRequest: urlRequest,
      httpResponse: httpResponse
    )
  }
}
