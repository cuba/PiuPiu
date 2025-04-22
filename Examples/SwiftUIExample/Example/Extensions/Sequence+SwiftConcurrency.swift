//
//  Sequence+SwiftConcurrency.swift
//  Example
//
//  Created by Jacob Sikorski on 2025-04-22.
//

import Foundation

extension Sequence {
  func asyncMap<T>(_ callback: @escaping @Sendable (Element) async throws -> T) async rethrows -> [T] {
    var results: [T] = []
    for element in self {
      try await results.append(callback(element))
    }
    return results
  }
  
  func asyncCompactMap<T>(_ callback: @escaping @Sendable (Element) async throws -> T?) async rethrows -> [T] {
    var results: [T] = []
    for element in self {
      guard let result = try await callback(element) else { continue }
      results.append(result)
    }
    return results
  }
  
  func asyncFlatMap<T>(_ callback: @escaping @Sendable (Element) async throws -> [T]) async rethrows -> [T] {
    var results: [T] = []
    for element in self {
      try await results.append(contentsOf: callback(element))
    }
    return results
  }
  
  func asyncForEach(_ callback: @escaping @Sendable (Element) async throws -> Void) async rethrows {
    for element in self {
      try await callback(element)
    }
  }
}

extension Sequence where Element: Sendable {
  func parallelMap<T: Sendable>(_ callback: @escaping @Sendable (Element) async throws -> T) async rethrows -> [T] {
    return try await withThrowingTaskGroup(of: (Int, T).self) { group in
      for tuple in self.enumerated() {
        group.addTask {
          return try await (tuple.offset, callback(tuple.element))
        }
      }
      
      var results: [(Int, T)] = []
      for try await newElement in group {
        results.append(newElement)
      }
      
      return results.sorted(by: { $0.0 < $1.0 }).map({ $0.1 })
    }
  }
  
  func parallelCompactMap<T: Sendable>(_ callback: @escaping @Sendable (Element) async throws -> T?) async rethrows -> [T] {
    return try await withThrowingTaskGroup(of: (Int, T?).self) { group in
      for tuple in self.enumerated() {
        group.addTask {
          return try await (tuple.offset, callback(tuple.element))
        }
      }
      
      var results: [(offset: Int, element: T)] = []
      for try await tuple in group {
        guard let element = tuple.1 else { continue }
        results.append((tuple.0, element))
      }
      return results.sorted(by: { $0.offset < $1.offset }).map(\.element)
    }
  }
  
  func parallelFlatMap<T: Sendable>(_ callback: @escaping @Sendable (Element) async throws -> [T]) async rethrows -> [T] {
    return try await withThrowingTaskGroup(of: (Int, [T]).self) { group in
      for tuple in self.enumerated() {
        group.addTask {
          return try await (tuple.offset, callback(tuple.element))
        }
      }
      
      var results: [(offset: Int, elements: [T])] = []
      for try await newElements in group {
        results.append(newElements)
      }
      return results.sorted(by: { $0.offset < $1.offset }).flatMap(\.elements)
    }
  }
  
  func parallelForEach(_ callback: @escaping @Sendable (Element) async throws -> Void) async rethrows {
    return await withThrowingTaskGroup(of: Void.self) { group in
      for element in self {
        group.addTask {
          try await callback(element)
        }
      }
    }
  }
}
