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
    public init() {}
    
    /// Converts a `String` into an `Int64`. If the string cannot be converted to a number, a `IntFromStringTransform.TransformError` is thrown.
    public func from(json: String, codingPath: [CodingKey]) throws -> Int64 {
        guard let integer = Int64(json) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Could not convert `\(json)` to `Int64`"))
        }
        
        return integer
    }
    
    /// Converts a `String` into an `Int64`. If the string cannot be converted to a number, a `IntFromStringTransform.TransformError` is thrown.
    public func toJSON(_ value: String, codingPath: [CodingKey]) throws -> Int64 {
        guard let integer = Int64(value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "Could not convert `\(value)` to `Int64`"))
        }
        
        return integer
    }
}
