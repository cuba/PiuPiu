//
//  StringFromIntTransform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// Converts an `Int64` into a `String` in both directions (to JSON and from JSON)
public class StringFromIntTransform: Transform {
    public init() {}
    
    /// Converts an `Int64` into a `String`. No error is ever thrown.
    public func transform(json: Int64) throws -> String {
        return "\(json)"
    }
    
    /// Converts an `Int64` into a `String`. No error is ever thrown.
    public func transform(value: Int64) throws -> String {
        return "\(value)"
    }
}
