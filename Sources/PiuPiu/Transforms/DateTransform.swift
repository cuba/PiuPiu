//
//  DateTransform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// Decodes a  `String` represented date to a `Date` object with a given `DateFormatter` and vice versa.
public class DateTransform: Transform {
  public let formatter: DateFormatter
  
  public init(formatter: DateFormatter, codingPath: [CodingKey]) {
    self.formatter = formatter
  }
  
  /// Decodes a  `String` represented date to a `Date` object using the specified `DateFormatter`. If the value cannot be decoded, `DateTransform.TransformError` will be thrown.
  public func from(json: String, codingPath: [CodingKey]) throws -> Date {
    guard let date = formatter.date(from: json) else {
      throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Could not convert `\(json)` to `Date` using formatter `\(String(describing: formatter))`"))
    }
    
    return date
  }
  
  /// Encodes a `Date` into its `String` representation using the specified `DateFormater`. No error is ever thrown because a `Date` can always be converted to string.
  public func toJSON(_ value: Date, codingPath: [CodingKey]) throws -> String {
    return formatter.string(from: value)
  }
}
