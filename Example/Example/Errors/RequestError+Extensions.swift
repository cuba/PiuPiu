//
//  RequestError+Extensions.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-04-19.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import PiuPiu

extension RequestError: BaseNetworkError {
    
    public var failureReason: String? {
        switch self {
        case .invalidURL            : return "ErrorReason.ApplicationError".localized()
        case .missingServerProvider : return "ErrorReason.ApplicationError".localized()
        case .missingURL            : return "ErrorReason.ApplicationError".localized()
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidURL            : return "RecoverySuggestion.UpdateVersion".localized()
        case .missingServerProvider : return "RecoverySuggestion.UpdateVersion".localized()
        case .missingURL            : return "RecoverySuggestion.UpdateVersion".localized()
        }
    }
    
    public static var errorDomain: String {
        return "PiuPiu.RequestError"
    }
    
    public var errorCode: Int {
        switch self {
        case .invalidURL            : return 0
        case .missingServerProvider : return 1
        case .missingURL            : return 2
        }
    }
}
