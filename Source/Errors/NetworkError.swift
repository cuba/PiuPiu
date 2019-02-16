//
//  NetworkError.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum NetworkError: BaseNetworkError {
    case noConnection
    
    public var errorKey: String {
        switch self {
        case .noConnection: return "NoConnection"
        }
    }
}

extension NetworkError {
    
    public var failureReason: String? {
        switch self {
        case .noConnection: return "ErrorReason.NoConnection".localized()
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .noConnection: return "RecoverySuggestion.EstablishConnection".localized()
        }
    }
}

extension NetworkError: CustomNSError {
    public static var errorDomain: String {
        return "NetworkKit.NetworkError"
    }
    
    public var errorCode: Int {
        switch self {
        case .noConnection: return 0
        }
    }
}
