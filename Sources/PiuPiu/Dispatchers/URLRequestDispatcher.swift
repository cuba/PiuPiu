//
//  URLRequestDispatcher.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-06-30.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import os.log

/// This is a convenience class for making URL requests in the form of futures.
/// It implements the `DataDispatcher`, `DownloadDispatcher`, `UploadDispatcher` protocols.
/// This class can be used in almost any setting.
@MainActor public final class URLRequestDispatcher: DataDispatcher, DownloadDispatcher, UploadDispatcher {
  /// The session to use for all requests
  public let session: URLSession
  /// Use this adapter to transform all requests on this dispatcher
  public weak var requestAdapter: URLRequestAdapter? = nil
  /// Use this adapter to transform all responses on this dispatcher
  public weak var responseAdapter: URLResponseAdapter? = nil
  
  /// Initialize this `Dispatcher` with `URLSessionConfiguration`.
  ///
  /// - Parameters:
  ///   - configuration: The configuration that will be used to create the `URLSession`.
  public init(
    session: URLSession = .shared,
    requestAdapter: URLRequestAdapter? = nil,
    responseAdapter: URLResponseAdapter? = nil
  ) {
    self.session = session
    self.requestAdapter = requestAdapter
    self.responseAdapter = responseAdapter
  }
  
  /// Send a given `URLRequest` and return a `Response<Data?>` object
  ///
  /// - Parameters:
  ///   - urlRequest: The `URLRequest` to send
  /// - Returns: The `Response<Data?>` object
  public func data(from urlRequest: URLRequest) async throws -> Response<Data?> {
    return try await adaptedData(from: urlRequest)
  }
  
  /// Send a given `URLRequest` and return a `Response<Data?>` object
  ///
  /// - Parameters:
  ///   - urlRequest: The `URLRequest` to send
  /// - Returns: The `Response<Data?>` object
  public func adaptedData(
    from urlRequest: URLRequest
  ) async throws -> Response<Data?> {
    let urlRequest = try await adaptedRequest(from: urlRequest, using: requestAdapter)
    let (data, urlResponse) = try await session.data(for: urlRequest)
    let adaptedResponse = try await adaptResponse(urlResponse: urlResponse, for: urlRequest, using: responseAdapter)
    return Response(body: data, urlRequest: urlRequest, urlResponse: adaptedResponse)
  }
  
  /// Download a file and save it to disk at the given destination
  ///
  /// - Parameters:
  ///   - request: The request to send
  /// - Returns: The response object with a URL where the file was stored
  public func download(from urlRequest: URLRequest, to destination: URL) async throws -> Response<URL> {
    return try await adaptedDownload(from: urlRequest, to: destination)
  }
  
  /// Download a file and save it to disk at the given destination
  ///
  /// - Parameters:
  ///   - request: The request to send
  /// - Returns: The response object with a URL where the file was stored
  public func adaptedDownload(
    from urlRequest: URLRequest,
    to destination: URL,
    requestAdapter: URLRequestAdapter? = nil,
    responseAdapter: URLResponseAdapter? = nil
  ) async throws -> Response<URL> {
    let urlRequest = try await adaptedRequest(from: urlRequest, using: requestAdapter)
    let (url, urlResponse) = try await session.download(for: urlRequest)
    try FileManager.default.moveItem(at: url, to: destination)
    let adaptedResponse = try await adaptResponse(urlResponse: urlResponse, for: urlRequest, using: responseAdapter)
    return Response(body: destination, urlRequest: urlRequest, urlResponse: adaptedResponse)
  }
  
  /// Create a future to make a data request.
  ///
  /// - Parameters:
  ///   - urlRequest: The request to send
  ///   - data: The data to send
  /// - Returns: The promise that will send the request.
  public func upload(for urlRequest: URLRequest, from data: Data) async throws -> Response<Data?> {
    return try await adaptedUpload(for: urlRequest, from: data)
  }
  
  /// Create a future to make a data request.
  ///
  /// - Parameters:
  ///   - urlRequest: The request to send
  ///   - data: The data to send
  /// - Returns: An AsyncThrowingStream witch will provide upload events
  public func uploadStream(
    for urlRequest: URLRequest,
    from data: Data
  ) async throws -> URLRequestStream<URLSessionUploadTask> {
    return try await adaptedUploadStream(for: urlRequest, from: data)
  }
  
  /// Create a future to make a data request.
  ///
  /// - Parameters:
  ///   - urlRequest: The request to send
  ///   - data: The data to send
  /// - Returns: The promise that will send the request.
  public func adaptedUploadStream(
    for urlRequest: URLRequest,
    from data: Data,
    requestAdapter: URLRequestAdapter? = nil,
    responseAdapter: URLResponseAdapter? = nil
  ) async throws -> URLRequestStream<URLSessionUploadTask> {
    let urlRequest = try await adaptedRequest(from: urlRequest, using: requestAdapter)
    return session.uploadTask(with: urlRequest, from: data).stream(responseAdapter: responseAdapter)
  }
  
  /// Create a future to make a data request.
  ///
  /// - Parameters:
  ///   - urlRequest: The request to send
  ///   - data: The data to send
  /// - Returns: The promise that will send the request.
  public func adaptedUpload(
    for urlRequest: URLRequest,
    from data: Data,
    requestAdapter: URLRequestAdapter? = nil,
    responseAdapter: URLResponseAdapter? = nil
  ) async throws -> Response<Data?> {
    let urlRequest = try await adaptedRequest(from: urlRequest, using: requestAdapter)
    let (data, urlResponse) = try await session.upload(for: urlRequest, from: data)
    let adaptedResponse = try await adaptResponse(urlResponse: urlResponse, for: urlRequest, using: responseAdapter)
    return Response(body: data, urlRequest: urlRequest, urlResponse: adaptedResponse)
  }
  
  /// Creates a ResponseFuture given the `callback` and adapts the given `urlRequest` if a `requestAdapter` is attached to this class
  /// If `requestAdapter` is not attached, a wrapped future will still be returned but its result is unchanged.
  private func adaptedRequest(
    from urlRequest: URLRequest,
    using adapter: URLRequestAdapter?
  ) async throws  -> URLRequest {
    return try await adapter?.adapt(
      urlRequest: urlRequest
    ) ?? urlRequest
  }
  
  /// Returns a wrapped future with an adapted `URLResponse` if a `responseAdapter` is attached to this class.
  /// If `responseAdapter` is not attached, a wrapped future will still be returned but its result is unchanged.
  private func adaptResponse(
    urlResponse: URLResponse,
    for urlRequest: URLRequest,
    using adapter: URLResponseAdapter?
  ) async throws -> URLResponse {
    try await adapter?.adapt(
      urlResponse: urlResponse,
      for: urlRequest
    ) ?? urlResponse
  }
}
