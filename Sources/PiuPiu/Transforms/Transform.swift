//
//  Transform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// Defines a protocol for encoding data to JSON
public protocol EncodingTransform {
  associatedtype ValueSource
  associatedtype JSONDestination: Encodable
  
  /// Transform any type to an `Encodable` type which will be encoded further by the `Encoder`.
  func toJSON(_ value: Self.ValueSource, codingPath: [CodingKey]) throws -> Self.JSONDestination
}

/// Defines a protocol for decoding data from JSON
public protocol DecodingTransform {
  associatedtype JSONSource: Decodable
  associatedtype ValueDestination
  
  /// Transform a `Decodable` value to any type. The `Decodable` type specified will be parsed by a `Decoder`.
  func from(json: Self.JSONSource, codingPath: [CodingKey]) throws -> Self.ValueDestination
}

/// A protocol that encompasses both `EncodingTransform` and `DecodingTransform`
public protocol Transform: EncodingTransform, DecodingTransform {}

public extension EncodingTransform {
  /// Transform any type to an `Encodable` type which will be encoded further by the `Encoder`.
  @available(*, deprecated, message: "Use `toJSON(Self.ValueSource, codingPath: [CodingKey])`")
  func transform(value: Self.ValueSource) throws -> Self.JSONDestination {
    return try toJSON(value, codingPath: [])
  }
}

public extension DecodingTransform {
  /// Transform a `Decodable` value to any type. The `Decodable` type specified will be parsed by a `Decoder`.
  @available(*, deprecated, message: "Use `from(json: Self.JSONSource, codingPath: [CodingKey])`")
  func transform(json: Self.JSONSource) throws -> Self.ValueDestination {
    return try from(json: json, codingPath: [])
  }
}
