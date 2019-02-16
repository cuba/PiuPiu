//
//  SerializationError.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum SerializationError: BaseNetworkError {
    case failedToDecodeResponseData(cause: Error?)
    case unexpectedEmptyResponse
    
    public var errorKey: String {
        switch self {
        case .failedToDecodeResponseData: return "InvalidObject"
        case .unexpectedEmptyResponse: return "EmptyResponse"
        }
    }
}

extension SerializationError: LocalizedError {
    
    public var failureReason: String? {
        switch self {
        case .failedToDecodeResponseData:
            return "ErrorReason.UnexpectedResponse".localized()
        case .unexpectedEmptyResponse:
            return "ErrorReason.EmptyResponse".localized()
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .failedToDecodeResponseData:
            return "RecoverySuggestion.UpdateVersion".localized()
        case .unexpectedEmptyResponse:
            return "RecoverySuggestion.UpdateVersion".localized()
        }
    }
}

extension SerializationError: CustomNSError {
    public static var errorDomain: String {
        return "NetworkKit.SerializationError"
    }
    
    public var errorCode: Int {
        switch self {
        case .failedToDecodeResponseData: return 0
        case .unexpectedEmptyResponse: return 1
        }
    }
}
