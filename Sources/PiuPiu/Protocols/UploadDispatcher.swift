//
//  UploadDispatcher.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-07-04.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation


/// The object that will be making the API call and returning the Future
public protocol UploadDispatcher {
  /// Create a future to make an upload request.
  ///
  /// - Parameters:
  ///   - data: The data to send
  ///   - request: The request to send
  /// - Returns: The data response
  func upload(for urlRequest: URLRequest, from data: Data) async throws -> Response<Data?>
}
