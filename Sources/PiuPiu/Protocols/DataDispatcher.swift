//
//  DataDispatcher.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-07-03.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// The object that will be making the API call and returning a response
@MainActor public protocol DataDispatcher {
  /// Send a given `URLRequest` and return a `Response<Data?>` object
  ///
  /// - Parameters:
  ///   - urlRequest: The `URLRequest` to send
  /// - Returns: The `Response<Data?>` object
  func data(from urlRequest: URLRequest) async throws -> Response<Data?>
}
