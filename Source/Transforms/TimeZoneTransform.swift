//
//  TimeZoneTransform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public class TimeZoneTransform: Transform {
    public enum TransformError: Error {
        case invalidIdentifier
    }
    
    public init() {
        // Empty
    }
    
    public func transform(json: String) throws -> TimeZone {
        guard let url = TimeZone(identifier: json) else {
            throw TransformError.invalidIdentifier
        }
        
        return url
    }
    
    public func transform(value: TimeZone) throws -> String {
        return value.identifier
    }
}
