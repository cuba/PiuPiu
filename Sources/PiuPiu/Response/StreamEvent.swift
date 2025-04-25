//
//  StreamEvent.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-03-21.
//

import Foundation

public struct StreamEvent<Key: Hashable & Sendable, Value: Sendable>: Sendable {
  public let type: Key
  public let data: Value
  
  public init(type: Key, data: Value) {
    self.type = type
    self.data = data
  }
}

extension StreamEvent {
  public func mapType<New: Sendable & Hashable>(_ callback: (Key) async throws -> New) async throws -> StreamEvent<New, Value> {
    do {
      let newType = try await callback(type)
      return .init(type: newType, data: data)
    } catch {
      throw EventStreamFailure(
        type: self.type,
        data: self.data,
        reason: error
      )
    }
  }
  
  public func mapData<New: Sendable>(_ callback: (Value) async throws -> New) async throws -> StreamEvent<Key, New> {
    do {
      let value = try await callback(data)
      return .init(type: type, data: value)
    } catch {
      throw EventStreamFailure(
        type: self.type,
        data: self.data,
        reason: error
      )
    }
  }
}

extension StreamEvent where Value == String {
  public func decode<T: Decodable & Sendable>(
    _ type: T.Type,
    using decoder: JSONDecoder,
    priority: TaskPriority? = nil
  ) async throws -> StreamEvent<Key, T> {
    return try await Task.detached(priority: priority) {
      do {
        let data = data.data(using: .utf8)!
        let decoded = try decoder.decode(type, from: data)
        return .init(type: self.type, data: decoded)
      } catch {
        throw EventStreamFailure(
          type: self.type,
          data: data,
          reason: error
        )
      }
    }.value
  }
}

public struct EventStreamFailure<Key: Hashable & Sendable, Value: Sendable, Failure: Error>: Error {
  let type: Key
  let data: Value
  let reason: Failure
}

extension EventStreamFailure: LocalizedError where Failure: LocalizedError {
  /// A localized message describing what error occurred.
  public var errorDescription: String? { reason.errorDescription }

  /// A localized message describing the reason for the failure.
  public var failureReason: String? { reason.failureReason }

  /// A localized message describing how one might recover from the failure.
  public var recoverySuggestion: String? { reason.recoverySuggestion }

  /// A localized message providing "help" text if the user requests help.
  public var helpAnchor: String? { reason.helpAnchor }
}

extension EventStreamFailure: Sendable where Failure: Sendable, Value: Sendable {}
extension EventStreamFailure: Equatable where Failure: Equatable, Value: Equatable {}
extension EventStreamFailure: Hashable where Failure: Hashable, Value: Hashable {}
