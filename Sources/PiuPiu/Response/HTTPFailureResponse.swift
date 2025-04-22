//
//  HTTPFailureResponse.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-03-17.
//

import Foundation

public struct HTTPFailureResponse<Reason: Error>: Error {
  public let reason: Reason
  public let statusCode: Unknowable<StatusCode>
  public let response: HTTPResponse<Data>
}

extension HTTPFailureResponse: LocalizedError where Reason: LocalizedError {
  /// A localized message describing what error occurred.
  public var errorDescription: String? {
    return reason.errorDescription
  }
  
  /// A localized message describing the reason for the failure.
  public var failureReason: String? {
    return reason.failureReason
  }

  /// A localized message describing how one might recover from the failure.
  public var recoverySuggestion: String? {
    return reason.recoverySuggestion
  }

  /// A localized message providing "help" text if the user requests help.
  public var helpAnchor: String? {
    return reason.helpAnchor
  }
}

extension HTTPFailureResponse: CustomDebugStringConvertible where Reason: CustomDebugStringConvertible {
  public var debugDescription: String {
    "Request failed: \(String(reflecting: reason))"
  }
}

extension HTTPFailureResponse: CustomStringConvertible where Reason: CustomStringConvertible {
  public var description: String {
    "Request failed: \(String(describing: reason))"
  }
}
