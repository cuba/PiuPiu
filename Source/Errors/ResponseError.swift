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
    case noResponse
    case notHTTPResponse
    case unexpectedEmptyResponse
    case failedToDecodeDataToString(encoding: String.Encoding)
    
    public var errorKey: String {
        switch self {
        case .noResponse:                   return "NoResponse"
        case .notHTTPResponse:              return "NotHTTPResponse"
        case .unexpectedEmptyResponse:      return "UnexpectedEmptyResponse"
        case .failedToDecodeDataToString:   return "FailedToDecodeDataToString"
        }
    }
}
