//
//  StringToIntTransform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// Converts a `String` into a `Int64` in both directions (to JSON and from JSON)
public class IntFromStringTransform: Transform {
    public enum TransformError: Error {
        case invalidIntegerString(received: String)
    }
    
    public init() {}
    
    /// Converts a `String` into an `Int64`. If the string cannot be converted to a number, a `IntFromStringTransform.TransformError` is thrown.
    public func transform(json: String) throws -> Int64 {
        guard let integer = Int64(json) else {
            throw TransformError.invalidIntegerString(received: json)
        }
        
        return integer
    }
    
    /// Converts a `String` into an `Int64`. If the string cannot be converted to a number, a `IntFromStringTransform.TransformError` is thrown.
    public func transform(value: String) throws -> Int64 {
        guard let integer = Int64(value) else {
            throw TransformError.invalidIntegerString(received: value)
        }
        
        return integer
    }
}
