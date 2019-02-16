//
//  ServerError.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum ServerError: BaseNetworkError {
    case internalServerError(cause: Error?)
    
    public var errorKey: String {
        switch self {
        case .internalServerError: return "InternalServerError"
        }
    }
}

extension ServerError: LocalizedError {
    public var failureReason: String? {
        switch self {
        case .internalServerError: return "ErrorReason.UnknownNetworkError".localized()
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .internalServerError: return "RecoverySuggestion.ContactSupport".localized()
        }
    }
}

extension ServerError: CustomNSError {
    public static var errorDomain: String {
        return "NetworkKit.ServerError"
    }
    
    public var errorCode: Int {
        switch self {
        case .internalServerError: return 0
        }
    }
}
