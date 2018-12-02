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
}

extension NetworkError {
    
    public var failureReason: String? {
        switch self {
        case .noConnection: return "Error.Reason.NoConnection".localized
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .noConnection: return "Error.RecoverySuggestion.EstablishConnection".localized
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
    
    public var key: String {
        switch self {
        case .noConnection: return "NoConnection"
        }
    }
}
