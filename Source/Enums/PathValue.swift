//
//  PathValue.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-10.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum PathValue: Equatable, CustomStringConvertible {
    case integer(_ value: Int)
    case string(_ value: String)
    
    public static func == (lhs: PathValue, rhs: PathValue) -> Bool {
        switch (lhs, rhs) {
        case (.integer(let lhsValue), .integer(let rhsValue)):
            return lhsValue == rhsValue
        case (.string(let lhsValue), .string(let rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
    
    public var description: String {
        switch self {
        case .string(let value):
            return value
        case .integer(let value):
            return "\(value)"
        }
    }
    
    public var string: String {
        return String(describing: self)
    }
}


public extension Sequence where Iterator.Element == PathValue {
    var string: String {
        return self.map({ $0.string }).joined(separator: "/")
    }
}
