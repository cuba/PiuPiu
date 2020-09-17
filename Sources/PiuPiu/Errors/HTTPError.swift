//
//  HTTPError.swift
//  PiuPiu iOS
//
//  Created by Jakub Sikorski on 2020-04-10.
//  Copyright © 2020 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum HTTPError: Error {
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
}
