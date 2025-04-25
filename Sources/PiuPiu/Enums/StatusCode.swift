//
//  StatusCode.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2018-12-02.
//  Copyright © 2018 Jacob Sikorski. All rights reserved.
//

import Foundation

/// The status code returned by the server.
///
/// - ok: 200
/// - created: 201
/// - accepted: 202
/// - noContent: 204
/// - resetContent: 205
/// - partialContent: 206
/// - multiStatus: 207
/// - alreadyReported: 208
/// - imUsed: 226
/// - badRequest: 400
/// - unauthorized: 401
/// - paymentRequired: 402
/// - forbidden: 403
/// - notFound: 404
/// - methodNotAllowed: 405
/// - notAcceptable: 406
/// - unprocessableEntity: 422
/// - conflict: 409
/// - gone: 410
/// - lengthRequired: 411
/// - unsupportedMediaType: 415
/// - internalServerError: 500
/// - notImplemented: 501
/// - badGateway: 502
/// - serviceUnavailable: 503
/// - gatewayTimeout: 504
/// - httpVersionNotSupported: 505
/// - other: Any status codes not covered by this enum.
public enum StatusCode: Int, CaseIterable, Sendable {
  case ok = 200
  case created = 201
  case accepted = 202
  case noContent = 204
  case resetContent = 205
  case partialContent = 206
  case multiStatus = 207
  case alreadyReported = 208
  case imUsed = 226
  case badRequest = 400
  case unauthorized = 401
  case paymentRequired = 402
  case forbidden = 403
  case notFound = 404
  case methodNotAllowed = 405
  case notAcceptable = 406
  case conflict = 409
  case gone = 410
  case lengthRequired = 411
  case unsupportedMediaType = 415
  case unprocessableEntity = 422
  case internalServerError = 500
  case notImplemented = 501
  case badGateway = 502
  case serviceUnavailable = 503
  case gatewayTimeout = 504
  case httpVersionNotSupported = 505
    
  /// The ype = status code falls under, such as 2xx (success), 4xx (client error) or 5xx (server error)
  public var type: StatusCodeType {
    switch rawValue {
    case 100..<200: .informational
    case 200..<300: .success
    case 300..<400: .redirect
    case 400..<500: .clientError
    default: .serverError
    }
  }
    
  /// Convenince method that returns `HTTPURLResponse.localizedString(forStatusCode: rawValue)`
  public var localizedDescription: String {
    return HTTPURLResponse.localizedString(forStatusCode: rawValue)
  }
  
  /// Returns any errors associated with this status code.
  /// This will always return a value unless the status code is either 1xx (informational), 2xx (success) or 3xx (rediect).
  public var httpError: HTTPError? {
    return switch type {
    case .clientError: HTTPError.clientError(self)
    case .serverError: HTTPError.serverError(self)
    case .invalid: HTTPError.invalidStatusCode(rawValue)
    case .success, .redirect, .informational: nil
    }
  }
  
  public static func == (lhs: StatusCode, rhs: StatusCode) -> Bool {
      return lhs.rawValue == rhs.rawValue
  }
}

/// The type of status code which refers to its number grouping such as 2xx (success) or 4xx (client error)
public enum StatusCodeType: Equatable, Sendable {
  /// 1xx
  case informational
  /// 2xx
  case success
  /// 3xx
  case redirect
  /// 4xx
  case clientError
  /// 5xx
  case serverError
  /// other
  case invalid
  
  /// Returns true if the response is typically considered as valid.
  /// This includes 1xx (informational), 2xx (success) and 3xx (redirect) response codes.
  public var isSuccessful: Bool {
    return switch self {
    case .informational: true
    case .success: true
    case .redirect: true
    case .clientError: false
    case .serverError: false
    case .invalid: false
    }
  }
  
  public var statusCodes: Set<StatusCode> {
    return Set(StatusCode.allCases.filter({ $0.type == self }))
  }
}

extension Unknowable where Entry == StatusCode {
  public var type: StatusCodeType {
    return switch self {
    case .known(let entry): entry.type
    case .unknown: .invalid
    }
  }
  
  public var httpError: HTTPError? {
    return switch self {
    case .known(let statusCode):
      statusCode.httpError
    case .unknown(let statusCode):
      HTTPError.invalidStatusCode(statusCode)
    }
  }
}
