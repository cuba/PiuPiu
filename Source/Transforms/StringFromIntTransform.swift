//
//  StringFromIntTransform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public class StringFromIntTransform: Transform {
    public init() {}
    
    public func transform(json: Int64) throws -> String {
        return "\(json)"
    }
    
    public func transform(value: Int64) throws -> String {
        return "\(value)"
    }
}
