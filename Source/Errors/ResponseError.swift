//
//  ResponseError.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A list of typical errors
public enum ResponseError: Error {
    case clientError(StatusCode)
    case serverError(StatusCode)
    case invalidStatusCode(StatusCode)
    case missingHTTPResponse
    
    public var errorKey: String {
        switch self {
        case .clientError:          return "ClientError"
        case .serverError:          return "ServerError"
        case .invalidStatusCode:    return "InvalidStatusCode"
        case .missingHTTPResponse:  return "MissingHTTPResponse"
        }
    }
}
