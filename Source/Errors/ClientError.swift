//
//  ClientError.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum ClientError: BaseNetworkError {
    case badRequest(cause: Error?)
    case unauthorized(cause: Error?)
    case forbidden(cause: Error?)
    case notFound(cause: Error?)
    case conflict(cause: Error?)
    case unprocessableEntity(cause: Error?)
    
    public var errorKey: String {
        switch self {
        case .badRequest:           return "BadRequest"
        case .unauthorized:         return "Unauthorized"
        case .forbidden:            return "Forbidden"
        case .notFound:             return "NotFound"
        case .conflict:             return "Conflict"
        case .unprocessableEntity:  return "UnprocessableEntity"
        }
    }
}

extension ClientError {
    public var failureReason: String? {
        switch self {
        case .badRequest:           return "ErrorReason.InvalidRequest".localized()
        case .unauthorized:         return "ErrorReason.NotAuthenticated".localized()
        case .forbidden:            return "ErrorReason.NotAuthorized".localized()
        case .notFound:             return "ErrorReason.ResourceNotFound".localized()
        case .conflict:             return "ErrorReason.UnknownNetworkError".localized()
        case .unprocessableEntity:  return "ErrorReason.InvalidRequest".localized()
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .badRequest:           return "RecoverySuggestion.ContactSupport".localized()
        case .notFound:             return "RecoverySuggestion.ContactSupport".localized()
        case .conflict:             return "RecoverySuggestion.ContactSupport".localized()
        default:                    return nil
        }
    }
}

extension ClientError: CustomNSError {
    public static var errorDomain: String {
        return "NetworkKit.ClientError"
    }
    
    public var errorCode: Int {
        switch self {
        case .badRequest:           return 0
        case .unauthorized:         return 1
        case .forbidden:            return 2
        case .notFound:             return 3
        case .conflict:             return 4
        case .unprocessableEntity:  return 5
        }
    }
}
