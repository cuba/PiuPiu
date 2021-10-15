//
//  URLFromStringTransform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// Decodes a `String` type to a `URL` and vice versa.
public class URLTransform: Transform {
    /// Initializes this transform.
    public init() {}
    
    /// Decodes a `String` into a `URL`. If the value cannot be decoded, a `URLTransform.TransformError` will be thrown.
    public func from(json: String, codingPath: [CodingKey]) throws -> URL {
        guard let url = URL(string: json) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Could not convert `\(json)` to `URL`"))
        }
        
        return url
    }
    
    /// Encodes a `URL` into a `String`. No error is ever thrown because a `URL` can always be converted to a `String`.
    public func toJSON(_ value: URL, codingPath: [CodingKey]) throws -> String {
        return value.absoluteString
    }
}
