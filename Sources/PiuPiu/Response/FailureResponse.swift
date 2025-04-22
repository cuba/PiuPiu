//
//  FailureResponse.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-03-17.
//

public struct FailureResponse<Body: Sendable>: Error {
  public let reason: Error
  public let response: Response<Body>
  
  public init(reason: Error, response: Response<Body>) {
    self.reason = reason
    self.response = response
  }
}
