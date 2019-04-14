//
//  DateEncodingStrategy+Extensions.swift
//  PewPew iOS
//
//  Created by Jacob Sikorski on 2019-03-01.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public extension JSONEncoder.DateEncodingStrategy {
    
    static var rfc3339: JSONEncoder.DateEncodingStrategy {
        return JSONEncoder.DateEncodingStrategy.formatted(DateFormatter.rfc3339)
    }
}

public extension JSONDecoder.DateDecodingStrategy {
    static var rfc3339: JSONDecoder.DateDecodingStrategy {
        return JSONDecoder.DateDecodingStrategy.formatted(DateFormatter.rfc3339)
    }
}
