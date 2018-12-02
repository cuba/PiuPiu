//
//  ResponseError.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation


public enum ResponseError: BaseNetworkError {
    case unknown(cause: Error?)
    
    public var key: String {
        switch self {
        case .unknown: return "Unknown"
        }
    }
}

extension ResponseError: LocalizedError {
    
    public var failureReason: String? {
        switch self {
        case .unknown: return "Error.Reason.UnexpectedResponse".localized
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .unknown: return "Error.RecoverySuggestion.ContactSupport".localized
        }
    }
}

extension ResponseError: CustomNSError {
    public static var errorDomain: String {
        return "NetworkKit.ResponseError"
    }
    
    public var errorCode: Int {
        switch self {
        case .unknown: return 0
        }
    }
}
