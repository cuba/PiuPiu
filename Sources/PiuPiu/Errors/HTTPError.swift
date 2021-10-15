//
//  HTTPError.swift
//  PiuPiu iOS
//
//  Created by Jakub Sikorski on 2020-04-10.
//  Copyright © 2020 Jacob Sikorski. All rights reserved.
//

import Foundation

/// An error object to cover any HTTP related errors
public enum HTTPError: LocalizedError {
    case clientError(StatusCode)
    case serverError(StatusCode)
    case invalidStatusCode(StatusCode)
    
    public var statusCode: StatusCode {
        switch self {
        case .clientError(let statusCode):
            return statusCode
        case .serverError(let statusCode):
            return statusCode
        case .invalidStatusCode(let statusCode):
            return statusCode
        }
    }
    
    public var errorDescription: String? {
        return statusCode.localizedDescription
    }
}
