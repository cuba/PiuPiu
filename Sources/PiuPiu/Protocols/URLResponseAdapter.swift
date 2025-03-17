//
//  URLResponseAdapter.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-03-17.
//

import Foundation

/// A protocol that allows to adapt or handle a response
public protocol URLResponseAdapter: Sendable {
  /// Adapt a response or perform some operations before returning the result.
  /// - Returns: An adapted response
  func adapt(urlResponse: URLResponse, for urlRequest: URLRequest) async throws -> URLResponse
}
