//
//  StringToIntTransform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public class IntFromStringTransform: Transform {
    public enum TransformError: Error {
        case invalidIntegerString(received: String)
    }
    
    public init() {}
    
    public func transform(json: String) throws -> Int64 {
        guard let integer = Int64(json) else {
            throw TransformError.invalidIntegerString(received: json)
        }
        
        return integer
    }
    
    public func transform(value: String) throws -> Int64 {
        guard let integer = Int64(value) else {
            throw TransformError.invalidIntegerString(received: value)
        }
        
        return integer
    }
}
