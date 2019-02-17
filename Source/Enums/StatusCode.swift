//
//  StatusCode.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2018-12-02.
//  Copyright © 2018 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum StatusCode {
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
    
    func error(cause: Error?) -> BaseNetworkError? {
        switch self {
        case .badRequest:           return ClientError.badRequest(cause: cause)
        case .unauthorized:         return ClientError.unauthorized(cause: cause)
        case .forbidden:            return ClientError.forbidden(cause: cause)
        case .notFound:             return ClientError.notFound(cause: cause)
        case .conflict:             return ClientError.conflict(cause: cause)
        case .unprocessableEntity:  return ClientError.unprocessableEntity(cause: cause)
        case .internalServerError:  return ServerError.internalServerError(cause: cause)
        default:
            if let error = cause {
                return ResponseError.unknown(cause: error)
            } else {
                return nil
            }
        }
    }
}
