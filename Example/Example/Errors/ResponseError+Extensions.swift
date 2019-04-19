//
//  ResponseError+Extensions.swift
//  PewPew
//
//  Created by Jacob Sikorski on 2019-04-19.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import PewPew

extension ResponseError: BaseNetworkError {
    
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
    
    public static var errorDomain: String {
        return "PewPew.ResponseError"
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
