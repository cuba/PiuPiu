//
//  HTTPError.swift
//  PiuPiu iOS
//
//  Created by Jakub Sikorski on 2020-04-10.
//  Copyright © 2020 Jacob Sikorski. All rights reserved.
//

import Foundation

/// An error object to cover any HTTP related errors
public enum HTTPError: Error, Hashable, Sendable {
  case clientError(StatusCode)
  case serverError(StatusCode)
  case invalidStatusCode(Int)
  
  public var statusCode: Unknowable<StatusCode> {
    switch self {
    case .clientError(let statusCode):
      return .known(statusCode)
    case .serverError(let statusCode):
      return .known(statusCode)
    case .invalidStatusCode(let statusCode):
      return .unknown(statusCode)
    }
  }
}

extension HTTPError: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .clientError(let statusCode):
      "Client error: \(statusCode.localizedDescription) (\(statusCode.rawValue))"
    case .serverError(let statusCode):
      "Server error: \(statusCode.localizedDescription) (\(statusCode.rawValue))"
    case .invalidStatusCode(let rawValue):
      "Invalid status code: \(rawValue)"
    }
  }
}

extension HTTPError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .clientError(let statusCode):
      "Client error: \(statusCode.localizedDescription) (\(statusCode.rawValue))"
    case .serverError(let statusCode):
      "Server error: \(statusCode.localizedDescription) (\(statusCode.rawValue))"
    case .invalidStatusCode(let rawValue):
      "Invalid status code: \(rawValue)"
    }
  }
}
