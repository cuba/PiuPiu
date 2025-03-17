//
//  StringFromIntTransform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// Converts an `Int64` into a `String` in both directions (to JSON and from JSON)
public class StringFromIntTransform: Transform {
  public init() {}
  
  /// Converts an `Int64` into a `String`. No error is ever thrown.
  public func from(json: Int64, codingPath: [CodingKey]) throws -> String {
    return "\(json)"
  }
  
  /// Converts an `Int64` into a `String`. No error is ever thrown.
  public func toJSON(_ value: Int64, codingPath: [CodingKey]) throws -> String {
    return "\(value)"
  }
}
