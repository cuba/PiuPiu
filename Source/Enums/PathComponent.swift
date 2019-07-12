//
//  PathComponent.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-10.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum PathComponent: Equatable, CustomStringConvertible {
    case constant(_ value: String)
    case wildcard(type: WildcardType)
    
    public var description: String {
        switch self {
        case .constant(let value):
            return value
        case .wildcard(let type):
            switch type {
            case .integer:
                return ":integer"
            case .string:
                return ":string"
            }
        }
    }
    
    public var displayValue: String {
        return String(describing: self)
    }
    
    public static func == (lhs: PathComponent, rhs: PathComponent) -> Bool {
        switch (lhs, rhs) {
        case (.constant(let lhsValue), .constant(let rhsValue)):
            return lhsValue == rhsValue
        case (.wildcard(let lhsType), .wildcard(let rhsType)):
            return lhsType == rhsType
        default:
            return false
        }
    }
}

public extension Sequence where Iterator.Element == PathComponent {
    var displayValue: String {
        return self.map({ $0.displayValue }).joined(separator: "/")
    }
}
