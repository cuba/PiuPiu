//
//  StatusCode.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2018-12-02.
//  Copyright © 2018 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum StatusCode: Int {
    case ok             = 200
    case created        = 201
    case noData         = 204
    case badRequest     = 400
    case unauthorized   = 401
    case forbidden      = 403
    case notFound       = 404
    case conflict       = 409
    
    case unprocessableEntity = 422
    case internalServerError = 500
    
    func error(cause: Error?) -> BaseNetworkError? {
        switch self {
        case .badRequest:           return ClientError.badRequest(cause: cause)
        case .unauthorized:         return ClientError.unauthorized(cause: cause)
        case .forbidden:            return ClientError.forbidden(cause: cause)
        case .notFound:             return ClientError.notFound(cause: cause)
        case .conflict:             return ClientError.conflict(cause: cause)
        case .unprocessableEntity:  return ClientError.unprocessableEntity(cause: cause)
        case .internalServerError:  return ServerError.internalServerError(cause: cause)
        default:                    return nil
        }
    }
}
