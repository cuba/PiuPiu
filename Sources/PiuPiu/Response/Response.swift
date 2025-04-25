//
//  ResponseInterface.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-02-21.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import os.log

/// A successful response object. This is retuned when there is any 2xx response.
public struct Response<Body: Sendable>: ResponseInterface {
  /// The data object that is attached to this response as specified by the user
  public let body: Body
  
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
  public init(body: Body, urlRequest: URLRequest, urlResponse: URLResponse) {
    self.body = body
    self.urlResponse = urlResponse
    self.urlRequest = urlRequest
  }
  
  /// Create a successful response object.
  ///
  /// - Parameters:
  ///   - response: the original response
  ///   - data: The data object to return
  public init<R: ResponseInterface>(response: R, body: Body) {
    self.body = body
    self.urlResponse = response.urlResponse
    self.urlRequest = response.urlRequest
  }
  
  public func adapted(with responseAdapter: URLResponseAdapter) async throws -> Self {
    let adapted = try await responseAdapter.adapt(urlResponse: urlResponse, for: urlRequest)
    return Self(body: body, urlRequest: urlRequest, urlResponse: adapted)
  }
}

extension Response where Body == Data? {
  /// Return a response where the `Body` is not nil
  /// - Returns: The `Response<Data>`
  /// - throws: `ResponseError.unexpectedEmptyResponse`
  public func ensureBody() throws -> Response<Data> {
    let data = try unwrapData()
    return Response<Data>(response: self, body: data)
  }
  
  /// Attempts to cast the `URLRequest` to a `HTTPURLResponse` and returns a wrapping `HTTPResponse` object if succesful.
  /// - Returns: The `HTTPResponse` object which wraps the `HTTPURLResponse`
  /// - throws: `ResponseError.notHTTPResponse`
  public func ensureHTTPResponse() throws -> HTTPResponse<Body> {
    return try HTTPResponse(response: self, body: body)
  }
  
  /// Ensures that the response contains a string body
  ///
  /// - Returns: `Response<String>`
  /// - throws: `ResponseError.unexpectedEmptyResponse`, `ResponseError.failedToDecodeDataToString`
  public func ensureStringBody(encoding: String.Encoding = .utf8) throws -> Response<String> {
    let response = try self.ensureBody()
    guard let stringBody = String(data: response.body, encoding: encoding) else {
      throw ResponseError.failedToDecodeDataToString(encoding: encoding)
    }
    
    return Response<String>(response: self, body: stringBody)
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
  ) async throws -> Response<D?> {
    return try await Response<D?>.init(
      body: self.decodeAsyncIfPresent(type, using: decoder, priority: priority),
      urlRequest: urlRequest,
      urlResponse: urlResponse
    )
  }
  
  /// Attempt to transform the response to a response containing a decoded object
  ///
  /// - Parameters:
  ///   - type: The Decodable type to decode
  ///   - decoder: The decoder to use.
  ///   - priority: The async priority to use
  /// - Returns: A response containing the decoded object
  /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
  /// - throws: An error if any value throws an error during decoding.
  public func ensureDecoded<D: Decodable & Sendable>(
    _ type: D.Type,
    using decoder: JSONDecoder = JSONDecoder(),
    priority: TaskPriority? = nil
  ) async throws -> Response<D> {
    return try await ensureBody().ensureDecoded(type, using: decoder, priority: priority)
  }
}

extension Response where Body == Data {
  /// Attempt to transform the response to a response containing a decoded object
  ///
  /// - Parameters:
  ///   - type: The Decodable type to decode
  ///   - decoder: The decoder to use.
  ///   - priority: The async priority to use
  /// - Returns: A response containing the decoded object
  /// - throws: An error if any value throws an error during decoding.
  public func ensureDecoded<D: Decodable & Sendable>(
    _ type: D.Type,
    using decoder: JSONDecoder = JSONDecoder(),
    priority: TaskPriority? = nil
  ) async throws -> Response<D> {
    return try await Response<D>.init(
      body: self.decodeAsync(type, using: decoder, priority: priority),
      urlRequest: urlRequest,
      urlResponse: urlResponse
    )
  }
}

extension Response {
  public func map<T>(_ transform: (Body) throws -> T) rethrows -> Response<T> {
    let body = try transform(body)
    return Response<T>(body: body, urlRequest: urlRequest, urlResponse: urlResponse)
  }
}

extension Response where Body: Sendable {
  public func asyncMap<T: Sendable>(_ transform: @Sendable (Body) async throws -> T) async rethrows -> Response<T> {
    let body = try await transform(body)
    return Response<T>(body: body, urlRequest: urlRequest, urlResponse: urlResponse)
  }
}

extension Response where Body == URL? {
  public func loadData(options: Data.ReadingOptions = []) throws -> Response<Data?> {
    try map { url in
      guard let url = url else { return nil }
      return try Data(contentsOf: url, options: options)
    }
  }
  
  public func asyncLoadData(options: Data.ReadingOptions = []) async throws -> Response<Data?> {
    return try await asyncMap { url in
      guard let url = url else { return nil }
      return try await Task.detached {
        try Data(contentsOf: url, options: options)
      }.value
    }
  }
}

extension Response where Body == URL {
  public func loadData(options: Data.ReadingOptions = []) throws -> Response<Data> {
    try map { url in
      try Data(contentsOf: body, options: options)
    }
  }
  
  public func asyncLoadData(options: Data.ReadingOptions = []) async throws -> Response<Data> {
    return try await asyncMap { url in
      try await Task.detached {
        try Data(contentsOf: body, options: options)
      }.value
    }
  }
}
