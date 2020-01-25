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
    public enum TransformError: Error {
        case invalidURL
    }
    
    /// Initializes this transform.
    public init() {}
    
    /// Decodes a `String` into a `URL`.  If the value cannot be decoded, a `URLTransform.TransformError` will be thrown.
    public func transform(json: String) throws -> URL {
        guard let url = URL(string: json) else {
            throw TransformError.invalidURL
        }
        
        return url
    }
    
    /// Encodes a `URL` into a `String`. No error is ever thrown because a `URL` can always be converted to a `String`.
    public func transform(value: URL) throws -> String {
        return value.absoluteString
    }
}
