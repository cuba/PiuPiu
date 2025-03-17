//
//  URLRequestAdapter.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-03-17.
//

import Foundation

/// A protocol that allows to adapt or handle a request
public protocol URLRequestAdapter: Sendable {
  /// Adapt a request or perform some operations before returning the result
  /// - Returns: An adapted request
  func adapt(urlRequest: URLRequest) async throws -> URLRequest
}
