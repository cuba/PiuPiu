//
//  EventStreamResult.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-03-25.
//

import Foundation
import os.log

public enum EventStreamResult<Element, Failure: Error> {
  case progress(Result<Element, Failure>)
  case response(URLResponse)
  
  public func logResponse(logger: Logger, urlRequest: URLRequest, isDetailed: Bool) {
    switch self {
    case .response(let response):
      response.log(
        logger: .stream,
        urlRequest: urlRequest,
        body: nil,
        isDetailed: isDetailed
      )
    case .progress:
      break
    }
  }
}

extension EventStreamResult where Element == StreamEvent<String, String>, Failure == Error {
  public func mapData<New>(_ callback: (Element) async throws -> New) async -> EventStreamResult<New, Failure> {
    switch self {
    case .response(let result):
      return .response(result)
    case .progress(let result):
      switch result {
      case .success(let success):
        do {
          let newValue = try await callback(success)
          return .progress(.success(newValue))
        } catch {
          return .progress(.failure(error))
        }
      case .failure(let failure):
        return .progress(.failure(failure))
      }
    }
  }
}

extension EventStreamResult where Element == StreamEvent<String, String>, Failure == Error {
  public func decode<T: Decodable & Sendable>(_ type: T.Type, using decoder: JSONDecoder, priority: TaskPriority? = nil) async -> EventStreamResult<StreamEvent<String, T>, Failure> {
    switch self {
    case .progress(let result):
      switch result {
      case .success(let success):
        do {
          let decoded = try await success.decode(type, using: decoder, priority: priority)
          return .progress(.success(decoded))
        } catch {
          return .progress(.failure(error))
        }
      case .failure(let failure):
        return .progress(.failure(failure))
      }
    case .response(let result):
      return .response(result)
    }
  }
}

extension EventStreamResult: Sendable where Element: Sendable {}
extension EventStreamResult: Equatable where Element: Equatable, Failure: Equatable {}
extension EventStreamResult: Hashable where Element: Hashable, Failure: Hashable {}
