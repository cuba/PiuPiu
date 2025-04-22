//
//  Dual.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-03-18.
//

public enum Dual<First, Second> {
  case first(First)
  case second(Second)
  
  public init(_ first: First) {
    self = .first(first)
  }
  
  public init(_ second: Second) {
    self = .second(second)
  }
}

extension Dual: Encodable where First: Encodable, Second: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .first(let value):
      try container.encode(value)
    case .second(let value):
      try container.encode(value)
    }
  }
}

extension Dual: Decodable where First: Decodable, Second: Decodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    
    if let firstValue = try? container.decode(First.self) {
      self = .first(firstValue)
    } else {
      let secondValue = try container.decode(Second.self)
      self = .second(secondValue)
    }
  }
}


extension Dual: Sendable where First: Sendable, Second: Sendable {}
extension Dual: Equatable where First: Equatable, Second: Equatable {}
extension Dual: Hashable where First: Hashable, Second: Hashable {}
extension Dual: Comparable where First: Comparable, Second: Comparable {}

extension Dual: CaseIterable where First: CaseIterable, Second: CaseIterable {
  public static var allCases: [Dual<First, Second>] {
    return First.allCases.map({ .first($0) }) + Second.allCases.map({ .second($0) })
  }
}

extension Dual: RawRepresentable where First: RawRepresentable, Second: RawRepresentable, First.RawValue == Second.RawValue {
  public typealias RawValue = First.RawValue
  
  public var rawValue: First.RawValue {
    switch self {
    case .first(let first): first.rawValue
    case .second(let second): second.rawValue
    }
  }
  
  public init?(rawValue: RawValue) {
    if let value = First(rawValue: rawValue) {
      self = .first(value)
    } else if let value = Second(rawValue: rawValue) {
      self = .second(value)
    } else {
      return nil
    }
  }
}
