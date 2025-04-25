//
//  DownloadDispatcher.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-07-03.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// The object that will be making the API call and returning the Future
@MainActor public protocol DownloadDispatcher: AnyObject {
  /// Download a file and save it to disk at the given destination
  ///
  /// - Parameters:
  ///   - request: The request to send
  /// - Returns: The response object with a URL where the file was stored
  func download(from urlRequest: URLRequest, to destination: URL) async throws -> Response<URL>
}
