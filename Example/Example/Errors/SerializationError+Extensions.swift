//
//  SerializationError+Extensions.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-04-19.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import PiuPiu

extension SerializationError: BaseNetworkError {
    
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
    
    public static var errorDomain: String {
        return "PiuPiu.SerializationError"
    }
    
    public var errorCode: Int {
        switch self {
        case .failedToDecodeResponseData: return 0
        case .unexpectedEmptyResponse: return 1
        }
    }
}
