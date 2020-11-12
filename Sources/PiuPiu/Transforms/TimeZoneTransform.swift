//
//  TimeZoneTransform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// Decodes a  time zone identifier represented as a `String` into a `TimeZone` and vice versa. An example of an identifier is `America/Montreal`. A time zone identifier (unlike an offset) has more regional information.
public class TimeZoneTransform: Transform {
    public enum TransformError: Error {
        case invalidIdentifier
    }
    
    public init() {
        // Empty
    }
    
    /// Decodes a  time zone identifier represented as a `String` into a `TimeZone`.  If the value cannot be decoded, a `TimeZoneTransform.TransformError` will be thrown.
    public func from(json: String, codingPath: [CodingKey]) throws -> TimeZone {
        guard let url = TimeZone(identifier: json) else {
            throw TransformError.invalidIdentifier
        }
        
        return url
    }
    
    /// Encodes a `TimeZone` into its identifier `String` representation. No error is ever thrown because a `TimeZone` can always be converted to an identifier.
    public func toJSON(_ value: TimeZone, codingPath: [CodingKey]) throws -> String {
        return value.identifier
    }
}
