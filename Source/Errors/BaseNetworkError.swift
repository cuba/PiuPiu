//
//  BaseNetworkError.swift
//  PewPew iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

public protocol BaseNetworkError: LocalizedError, CustomNSError {
    var errorKey: String { get }
}

extension BaseNetworkError  {
    public var errorDescription: String? {
        var parts: [String] = []
        
        if let failureReason = failureReason {
            parts.append(failureReason)
        }
        
        if let recoverySuggestion = recoverySuggestion {
            parts.append(recoverySuggestion)
        }
        
        if parts.count > 0 {
            return parts.joined(separator: " ")
        } else {
            return "ErrorReason.UnknownNetworkError".localized()
        }
    }
    
    public var errorUserInfo: [String : Any] {
        var userInfo: [String: Any] = [
            NSDebugDescriptionErrorKey: errorKey
        ]
        
        var tempUserInfo: [String: Any?] = [
            NSLocalizedDescriptionKey: errorDescription,
            NSLocalizedFailureReasonErrorKey: failureReason,
            NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion
        ]
        
        if #available(iOS 11.0, *) {
            tempUserInfo[NSLocalizedFailureErrorKey] = errorDescription
        }
        
        for (key, value) in tempUserInfo {
            guard let value = value else { continue }
            userInfo[key] = value
        }
        
        return userInfo
    }
}
