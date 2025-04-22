//
//  EmptyStringTransform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// Filters out empty strings and returns a nil value in both directions (to JSON and from JSON)
public class EmptyStringTransform: Transform {
  public init() {}
  
  /// Filters out empty strings and returns a nil value.
  public func from(json: String, codingPath: [CodingKey]) throws -> String? {
    if !json.isEmpty {
      return json
    } else {
      return nil
    }
  }
  
  /// Filters out empty strings and returns a nil value.
  public func toJSON(_ value: String, codingPath: [CodingKey]) throws -> String? {
    if !value.isEmpty {
      return value
    } else {
      return nil
    }
  }
}
