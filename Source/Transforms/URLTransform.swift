//
//  URLFromStringTransform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public class URLTransform: Transform {
    public enum TransformError: Error {
        case invalidURL
    }
    
    public init() {}
    
    public func transform(json: String) throws -> URL {
        guard let url = URL(string: json) else {
            throw TransformError.invalidURL
        }
        
        return url
    }
    
    public func transform(value: URL) throws -> String {
        return value.absoluteString
    }
}
