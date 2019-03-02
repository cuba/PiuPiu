//
//  StatusCode.swift
//  NetworkKit iOS
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
public enum StatusCode: Equatable {
    
    static let predefined: [StatusCode] = [
        .ok, .created, .accepted, .noContent, .resetContent, .partialContent, .multiStatus, .alreadyReported, .imUsed,
        .badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound, .methodNotAllowed, .notAcceptable, .unprocessableEntity, .conflict, .gone, .lengthRequired, .unsupportedMediaType,
        .internalServerError, .notImplemented, .badGateway, .serviceUnavailable, .gatewayTimeout, .httpVersionNotSupported
    ]
    
    /// 2xx
    case ok
    case created
    case accepted
    case noContent
    case resetContent
    case partialContent
    case multiStatus
    case alreadyReported
    case imUsed
    
    /// 4xx
    case badRequest
    case unauthorized
    case paymentRequired
    case forbidden
    case notFound
    case methodNotAllowed
    case notAcceptable
    case unprocessableEntity
    case conflict
    case gone
    case lengthRequired
    case unsupportedMediaType
    
    /// 5xx
    case internalServerError
    case notImplemented
    case badGateway
    case serviceUnavailable
    case gatewayTimeout
    case httpVersionNotSupported
    
    case other(Int)
    
    public var rawValue: Int {
        switch self {
        case .ok                        : return 200
        case .created                   : return 201
        case .accepted                  : return 202
        case .noContent                 : return 204
        case .resetContent              : return 205
        case .partialContent            : return 206
        case .multiStatus               : return 207
        case .alreadyReported           : return 208
        case .imUsed                    : return 226
        case .badRequest                : return 400
        case .unauthorized              : return 401
        case .paymentRequired           : return 402
        case .forbidden                 : return 403
        case .notFound                  : return 404
        case .methodNotAllowed          : return 405
        case .notAcceptable             : return 406
        case .unprocessableEntity       : return 422
        case .conflict                  : return 409
        case .gone                      : return 410
        case .lengthRequired            : return 411
        case .unsupportedMediaType      : return 415
        case .internalServerError       : return 500
        case .notImplemented            : return 501
        case .badGateway                : return 502
        case .serviceUnavailable        : return 503
        case .gatewayTimeout            : return 504
        case .httpVersionNotSupported   : return 505
        case .other(let value)          : return value
        }
    }
    
    var type: StatusCodeType {
        switch rawValue {
        case 100..<200: return .informational
        case 200..<300: return .success
        case 300..<400: return .redirect
        case 400..<500: return .clientError
        case 500..<600: return .serverError
        default       : return .invalid
        }
    }
    
    public init(rawValue: Int) {
        if let statusCode = StatusCode.predefined.first(where: { $0.rawValue == rawValue }) {
            self = statusCode
        } else {
            self = StatusCode.other(rawValue)
        }
    }
    
    func makeError(cause: Error?) -> ResponseError? {
        switch self {
        case .badRequest:           return ResponseError.badRequest(cause: cause)
        case .unauthorized:         return ResponseError.unauthorized(cause: cause)
        case .forbidden:            return ResponseError.forbidden(cause: cause)
        case .notFound:             return ResponseError.notFound(cause: cause)
        case .conflict:             return ResponseError.conflict(cause: cause)
        case .unprocessableEntity:  return ResponseError.unprocessableEntity(cause: cause)
        case .internalServerError:  return ResponseError.internalServerError(cause: cause)
        case .serviceUnavailable:   return ResponseError.serviceUnavailable(cause: cause)
        default:
            if !type.isSuccessful {
                switch type {
                case .clientError:
                    return ResponseError.otherClientError(cause: cause)
                case .serverError:
                    return ResponseError.otherServerError(cause: cause)
                default:
                    return ResponseError.unknown(cause: cause)
                }
            } else if let error = cause {
                return ResponseError.unknown(cause: error)
            } else {
                return nil
            }
        }
    }
    
    public static func == (lhs: StatusCode, rhs: StatusCode) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

public enum StatusCodeType: Equatable {
    case informational
    case success
    case redirect
    case clientError
    case serverError
    case invalid
    
    public var isSuccessful: Bool {
        switch self {
        case .informational : return true
        case .success       : return true
        case .redirect      : return true
        case .clientError   : return false
        case .serverError   : return false
        case .invalid       : return false
        }
    }
}
