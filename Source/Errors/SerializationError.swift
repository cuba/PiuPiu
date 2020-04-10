//
//  SerializationError.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum SerializationError: Error {
    case unexpectedEmptyResponse
    case failedToDecodeDataToString(encoding: String.Encoding)
    
    public var errorKey: String {
        switch self {
        case .unexpectedEmptyResponse   : return "UnexpectedEmptyResponse"
        case .failedToDecodeDataToString: return "FailedToDecodeDataToString"
        }
    }
}
