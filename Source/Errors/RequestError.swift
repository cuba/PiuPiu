//
//  RequestError.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2019-02-16.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum RequestError: BaseNetworkError {
    case invalidURL(cause: Error)
    case missingServerProvider
    
    public var errorKey: String {
        switch self {
        case .invalidURL            : return "InvalidURL"
        case .missingServerProvider : return "MissingServerProvider"
        }
    }
}

extension RequestError: LocalizedError {
    
    public var failureReason: String? {
        switch self {
        case .invalidURL            : return "ErrorReason.ApplicationError".localized()
        case .missingServerProvider : return "ErrorReason.ApplicationError".localized()
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidURL            : return "RecoverySuggestion.UpdateVersion".localized()
        case .missingServerProvider : return "RecoverySuggestion.UpdateVersion".localized()
        }
    }
}

extension RequestError: CustomNSError {
    public static var errorDomain: String {
        return "NetworkKit.RequestError"
    }
    
    public var errorCode: Int {
        switch self {
        case .invalidURL            : return 0
        case .missingServerProvider : return 1
        }
    }
}
