//
//  EmptyStringTransform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public class EmptyStringTransform: Transform {
    public init() {}
    
    public func transform(json: String) throws -> String? {
        if !json.isEmpty {
            return json
        } else {
            return nil
        }
    }
    
    public func transform(value: String) throws -> String? {
        if !value.isEmpty {
            return value
        } else {
            return nil
        }
    }
}
