//
//  SerializationError.swift
//  PewPew iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum SerializationError: Error {
    case failedToDecodeResponseData(cause: Error?)
    case unexpectedEmptyResponse
    
    public var errorKey: String {
        switch self {
        case .failedToDecodeResponseData: return "InvalidObject"
        case .unexpectedEmptyResponse: return "EmptyResponse"
        }
    }
}
