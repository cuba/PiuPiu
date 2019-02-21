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
/// - noData: 204
/// - badRequest: 400
/// - unauthorized: 401
/// - forbidden: 403
/// - notFound: 404
/// - unprocessableEntity: 422
/// - conflict: 409
/// - internalServerError: 500
/// - other: Any status codes not covered by this enum.
public enum StatusCode: Equatable {
    case ok
    case created
    case noData
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case unprocessableEntity
    case conflict
    case internalServerError
    case other(Int)
    
    var rawValue: Int {
        switch self {
        case .ok                    : return 200
        case .created               : return 201
        case .noData                : return 204
        case .badRequest            : return 400
        case .unauthorized          : return 401
        case .forbidden             : return 403
        case .notFound              : return 404
        case .unprocessableEntity   : return 422
        case .conflict              : return 409
        case .internalServerError   : return 500
        case .other(let value)      : return value
        }
    }
    
    init(rawValue: Int) {
        switch rawValue {
        case StatusCode.ok.rawValue                     : self = .ok
        case StatusCode.created.rawValue                : self = .created
        case StatusCode.noData.rawValue                 : self = .noData
        case StatusCode.badRequest.rawValue             : self = .badRequest
        case StatusCode.unauthorized.rawValue           : self = .unauthorized
        case StatusCode.forbidden.rawValue              : self = .forbidden
        case StatusCode.notFound.rawValue               : self = .notFound
        case StatusCode.conflict.rawValue               : self = .conflict
        case StatusCode.unprocessableEntity.rawValue    : self = .unprocessableEntity
        case StatusCode.internalServerError.rawValue    : self = .internalServerError
        default                                         : self = .other(rawValue)
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
        default:
            if let error = cause {
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
