//
//  UnknowableType.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-03-17.
//

public enum UnknowableType<Entry: RawRepresentable>: RawRepresentable {
  public init(_ rawValue: Entry.RawValue) {
    if let entry = Entry(rawValue: rawValue) {
      self = .known(entry)
    } else {
      self = .unknown(rawValue)
    }
  }
  
  public init?(rawValue: Entry.RawValue) {
    if let entry = Entry(rawValue: rawValue) {
      self = .known(entry)
    } else {
      self = .unknown(rawValue)
    }
  }

  public var rawValue: Entry.RawValue {
    return switch self {
    case .known(let entry): entry.rawValue
    case .unknown(let rawValue): rawValue
    }
  }

  case known(Entry)
  case unknown(Entry.RawValue)

  public var known: Entry? {
    return switch self {
    case .known(let entry): entry
    case .unknown: nil
    }
  }
}

extension UnknowableType: Decodable where Entry.RawValue: Decodable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(Entry.RawValue.self)

    if let entry = Entry(rawValue: rawValue) {
      self = .known(entry)
    } else {
      self = .unknown(rawValue)
    }
  }
}

extension UnknowableType: Encodable where Entry.RawValue: Encodable {
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

extension UnknowableType: Sendable where Entry: Sendable, Entry.RawValue: Sendable {}
extension UnknowableType: Equatable where Entry: Equatable, Entry.RawValue: Equatable {}
extension UnknowableType: Hashable where Entry: Hashable, Entry.RawValue: Hashable {}
extension UnknowableType: Comparable where Entry: Comparable, Entry.RawValue: Comparable {}
