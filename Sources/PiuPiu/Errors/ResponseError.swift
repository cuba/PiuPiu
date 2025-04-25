//
//  ResponseError.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A list of typical errors
public enum ResponseError: Error {
  case notHTTPResponse
  case unexpectedEmptyResponse
  case failedToDecodeDataToString(encoding: String.Encoding)
}
