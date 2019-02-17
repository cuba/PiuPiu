//
//  ResponseError.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation


public enum ResponseError: BaseNetworkError {
    case badRequest(cause: Error?)
    case unauthorized(cause: Error?)
    case forbidden(cause: Error?)
    case notFound(cause: Error?)
    case conflict(cause: Error?)
    case unprocessableEntity(cause: Error?)
    case unknown(cause: Error?)
    case internalServerError(cause: Error?)
    
    public var errorKey: String {
        switch self {
        case .badRequest            : return "BadRequest"
        case .unauthorized          : return "Unauthorized"
        case .forbidden             : return "Forbidden"
        case .notFound              : return "NotFound"
        case .conflict              : return "Conflict"
        case .unprocessableEntity   : return "UnprocessableEntity"
        case .internalServerError   : return "InternalServerError"
        case .unknown               : return "Unknown"
        }
    }
}

extension ResponseError: LocalizedError {
    
    public var failureReason: String? {
        switch self {
        case .badRequest:           return "ErrorReason.InvalidRequest".localized()
        case .unauthorized:         return "ErrorReason.NotAuthenticated".localized()
        case .forbidden:            return "ErrorReason.NotAuthorized".localized()
        case .notFound:             return "ErrorReason.ResourceNotFound".localized()
        case .conflict:             return "ErrorReason.UnknownNetworkError".localized()
        case .unprocessableEntity:  return "ErrorReason.InvalidRequest".localized()
        case .internalServerError:  return "ErrorReason.UnknownNetworkError".localized()
        case .unknown:              return "ErrorReason.UnexpectedResponse".localized()
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .badRequest            : return "RecoverySuggestion.ContactSupport".localized()
        case .notFound              : return "RecoverySuggestion.ContactSupport".localized()
        case .conflict              : return "RecoverySuggestion.ContactSupport".localized()
        case .unknown               : return "RecoverySuggestion.ContactSupport".localized()
        case .internalServerError   : return "RecoverySuggestion.ContactSupport".localized()
        default                     : return nil
        }
    }
}

extension ResponseError: CustomNSError {
    public static var errorDomain: String {
        return "NetworkKit.ResponseError"
    }
    
    public var errorCode: Int {
        switch self {
        case .unknown               : return 0
        case .badRequest            : return 1
        case .unauthorized          : return 2
        case .forbidden             : return 3
        case .notFound              : return 4
        case .unprocessableEntity   : return 5
        case .conflict              : return 6
        case .internalServerError   : return 7
        }
    }
}
