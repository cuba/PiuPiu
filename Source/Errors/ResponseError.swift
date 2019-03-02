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
    case internalServerError(cause: Error?)
    case serviceUnavailable(cause: Error?)
    case otherClientError(cause: Error?)
    case otherServerError(cause: Error?)
    case unknown(cause: Error?)
    
    public var errorKey: String {
        switch self {
        case .badRequest            : return "BadRequest"
        case .unauthorized          : return "Unauthorized"
        case .forbidden             : return "Forbidden"
        case .notFound              : return "NotFound"
        case .conflict              : return "Conflict"
        case .unprocessableEntity   : return "UnprocessableEntity"
        case .internalServerError   : return "InternalServerError"
        case .serviceUnavailable    : return "ServiceUnavailable"
        case .otherClientError      : return "OtherClientError"
        case .otherServerError      : return "OtherClientError"
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
        case .serviceUnavailable:   return "ErrorReason.ServiceUnavailable".localized()
        case .otherClientError:     return "ErrorReason.InvalidRequest".localized()
        case .otherServerError:     return "ErrorReason.UnknownNetworkError".localized()
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
        case .serviceUnavailable    : return "RecoverySuggestion.TemporaryDowntime".localized()
        case .otherClientError      : return "RecoverySuggestion.ContactSupport".localized()
        case .otherServerError      : return "RecoverySuggestion.ContactSupport".localized()
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
        case .otherClientError      : return 1
        case .otherServerError      : return 2
        case .badRequest            : return 3
        case .unauthorized          : return 4
        case .forbidden             : return 5
        case .notFound              : return 6
        case .unprocessableEntity   : return 7
        case .conflict              : return 8
        case .internalServerError   : return 9
        case .serviceUnavailable    : return 10
        }
    }
}
