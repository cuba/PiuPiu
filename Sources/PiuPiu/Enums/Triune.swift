//
//  Alternative.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-03-18.
//

public enum Triune<First, Second, Third> {
  case first(First)
  case second(Second)
  case third(Third)
  
  public init(_ first: First) {
    self = .first(first)
  }
  
  public init(_ second: Second) {
    self = .second(second)
  }
  
  public init(_ third: Third) {
    self = .third(third)
  }
}

extension Triune: Encodable where First: Encodable, Second: Encodable, Third: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .first(let value):
      try container.encode(value)
    case .second(let value):
      try container.encode(value)
    case .third(let value):
      try container.encode(value)
    }
  }
}

extension Triune: Decodable where First: Decodable, Second: Decodable, Third: Decodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    
    if let firstValue = try? container.decode(First.self) {
      self = .first(firstValue)
    } else if let secondValue = try? container.decode(Second.self) {
      self = .second(secondValue)
    } else {
      let thirdValue = try container.decode(Third.self)
      self = .third(thirdValue)
    }
  }
}

extension Triune: Sendable where First: Sendable, Second: Sendable, Third: Sendable {}
extension Triune: Equatable where First: Equatable, Second: Equatable, Third: Equatable {}
extension Triune: Hashable where First: Hashable, Second: Hashable, Third: Hashable {}
extension Triune: Comparable where First: Comparable, Second: Comparable, Third: Comparable {}

extension Triune: CaseIterable where First: CaseIterable, Second: CaseIterable, Third: CaseIterable {
  public static var allCases: [Triune<First, Second, Third>] {
    return First.allCases.map({ .first($0) })
    + Second.allCases.map({ .second($0) })
    + Third.allCases.map({ .third($0) })
  }
}

extension Triune: RawRepresentable where First: RawRepresentable, Second: RawRepresentable, Third: RawRepresentable, First.RawValue == Second.RawValue, First.RawValue == Third.RawValue {
  public typealias RawValue = First.RawValue
  
  public var rawValue: First.RawValue {
    switch self {
    case .first(let first): first.rawValue
    case .second(let second): second.rawValue
    case .third(let third): third.rawValue
    }
  }
  
  public init?(rawValue: RawValue) {
    if let value = First(rawValue: rawValue) {
      self = .first(value)
    } else if let value = Second(rawValue: rawValue) {
      self = .second(value)
    } else if let value = Third(rawValue: rawValue) {
      self = .third(value)
    } else {
      return nil
    }
  }
}
