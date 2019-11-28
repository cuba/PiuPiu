//
//  DateTransform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public class DateTransform: Transform {
    public let formatter: DateFormatter
    
    public init(formatter: DateFormatter) {
        self.formatter = formatter
    }
    
    public enum TransformError: Error {
        case invalidDateFormat(expectedFormat: String, received: String)
    }
    
    public func transform(json: String) throws -> Date {
        guard let date = formatter.date(from: json) else {
            throw TransformError.invalidDateFormat(expectedFormat: formatter.dateFormat, received: json)
        }
        
        return date
    }
    
    public func transform(value: Date) throws -> String {
        return formatter.string(from: value)
    }
}
