//
//  SerializationError.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum SerializationError: BaseNetworkError {
    case invalidObject
    case emptyResponse
    
    public var key: String {
        switch self {
        case .invalidObject: return "InvalidObject"
        case .emptyResponse: return "EmptyResponse"
        }
    }
}

extension SerializationError: LocalizedError {
    
    public var failureReason: String? {
        switch self {
        case .invalidObject:
            return "Error.Reason.UnexpectedResponse".localized
        case .emptyResponse:
            return "Error.Reason.UnexpectedResponse".localized
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidObject:
            return "Error.RecoverySuggestion.ContactSupport".localized
        case .emptyResponse:
            return "Error.RecoverySuggestion.ContactSupport".localized
        }
    }
}

extension SerializationError: CustomNSError {
    public static var errorDomain: String {
        return "NetworkKit.SerializationError"
    }
    
    public var errorCode: Int {
        switch self {
        case .invalidObject: return 0
        case .emptyResponse: return 1
        }
    }
}
