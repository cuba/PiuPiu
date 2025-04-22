//
//  EventStream.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-03-21.
//

import Foundation
import os.log

public final class EventStream: AsyncSequence {
  public typealias AsyncIterator = EventStreamIterator
  public typealias Element = EventStreamIterator.Element
  private let session: URLSession
  private let urlRequest: URLRequest
  
  public init(session: URLSession, urlRequest: URLRequest) {
    self.session = session
    self.urlRequest = urlRequest
  }
  
  public func makeAsyncIterator() -> EventStreamIterator {
    let stream = EventStreamIterator(session: session, urlRequest: urlRequest)
    Task {
      await stream.startFetching()
    }
    return stream
  }
}

/// An endless sequence iterator for the given resource
public final actor EventStreamIterator: NSObject, AsyncIteratorProtocol {
  private static let eventPrefix = "event:"
  private static let dataPrefix = "data:"
  public typealias Element = EventStreamResult<StreamEvent<String, String>, Error>
  public typealias Failure = Error
  
  let session: URLSession
  let urlRequest: URLRequest
  
  private var remaining: String? = nil
  private var queue: [Result<StreamEvent<String, String>, Error>] = []
  private var data = Data()
  private var task: URLSessionDataTask?
  private var pendingResponse: URLResponse? = nil
  private var pendingError: Error? = nil
  
  private(set) var response: URLResponse? = nil
  private(set) var error: Error? = nil
  private(set) var isCompleted = false
  
  public init(session: URLSession, urlRequest: URLRequest) {
    self.session = session
    self.urlRequest = urlRequest
  }
  
  func startFetching() {
    let task = session.dataTask(with: urlRequest)
    task.delegate = self
    task.resume()
    self.task = task
  }
  
  /// Returns the next downloaded value if it has changed since last time it was downloaded. Will return a cached result as an initial value.
  ///
  /// - Note: Only throws `CancellationError` error. Downloading errors are returned as a `Result` object
  public func next() async throws -> Element? {
    // Keep fetching new data until we get a new result
    while true {
      if let event = try processData() {
        switch event {
        case .success(let event):
          Logger.stream.debug("""
          event: '\(event.type)'
          data:  \(event.data)
          """)
        case .failure(let error):
          Logger.stream.debug("Failed event: `\(String(reflecting: error))`")
        }
        
        return .progress(event)
      } else {
        guard !isCompleted else {
          return nil
        }
        
        if let pendingResponse {
          self.pendingResponse = nil
          return .response(pendingResponse)
        } else if let pendingError {
          self.pendingError = nil
          self.isCompleted = true
          throw pendingError
        }
        
        try await Task.sleep(for: .seconds(0.25))
      }
    }
  }
  
  private func processData() throws -> Result<StreamEvent<String, String>, Error>? {
    let data = data
    self.data = Data()
    
    guard let string = String(data: data, encoding: .utf8) else {
      Logger.stream.error("Stream data is not a utf8 string: \(String(describing: data), privacy: .private)")
      throw StreamDataError.invalidFormat("Stream data is not a utf8 string")
    }
    
    let lines = string.components(separatedBy: .newlines)
    let decoded = Self.decodeEvents(lines: lines)
    
    if let remaining = decoded.remaining, !remaining.isEmpty, let data = remaining.data(using: .utf8) {
      self.data = data
      Logger.stream.debug("Queueing remaining: \(remaining)")
    }
    
    queue += decoded.results
    
    if queue.isEmpty {
      return nil
    } else {
      return queue.removeFirst()
    }
  }
  
  private func process(_ data: Data) {
    self.data += data
  }
  
  nonisolated
  private static func parse(eventPart: String, dataPart: String) throws -> StreamEvent<String, String> {
    guard let eventPrefixRange = eventPart.range(of: Self.eventPrefix) else {
      Logger.stream.error("Missing event prefix for: \(eventPart, privacy: .private)")
      throw StreamDataError.missingEventPrefix
    }
    guard eventPrefixRange.lowerBound == eventPart.startIndex else {
      Logger.stream.error("Missing event prefix for: \(eventPart, privacy: .private)")
      throw StreamDataError.missingEventPrefix
    }
    guard let dataPrefixRange = dataPart.range(of: Self.dataPrefix) else {
      Logger.stream.error("Missing data prefix for: \(dataPart, privacy: .private)")
      throw StreamDataError.missingDataPrefix
    }
    guard dataPrefixRange.lowerBound == dataPart.startIndex else {
      Logger.stream.error("Missing data prefix for: \(dataPart, privacy: .private)")
      throw StreamDataError.missingDataPrefix
    }
    
    let eventText = eventPart[eventPrefixRange.upperBound..<eventPart.endIndex]
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let dataText = dataPart[dataPrefixRange.upperBound..<dataPart.endIndex]
    return StreamEvent(type: eventText, data: String(dataText))
  }
  
  nonisolated
  static func decodeEvents(lines: [String]) -> (results: [Result<StreamEvent<String, String>, Error>], remaining: String?) {
    var results: [Result<StreamEvent<String, String>, Error>] = []
    var currentPart: [String] = []
    var lines = lines
    
    // Separate the data with empty lines
    while !lines.isEmpty {
      let line = lines.removeFirst()
      
      if line.isEmpty {
        if !currentPart.isEmpty {
          do {
            if let event = try decodeEvent(lines: currentPart) {
              results.append(.success(event))
            }
          } catch {
            results.append(.failure(error))
          }
        }
        currentPart = []
      } else {
        currentPart.append(line)
      }
    }
    
    if !currentPart.isEmpty {
      Logger.stream.warning("""
      Incomplete Event:
      ```
      \(currentPart.joined(separator: "\n"))
      ```
      """)
    }
    
    return (results, currentPart.joined(separator: "\n"))
  }
  
  nonisolated
  private static func decodeEvent(lines: [String]) throws -> StreamEvent<String, String>? {
    var lines = lines
    
    while lines.count > 1 {
      let eventPart = lines.removeFirst().trimmingCharacters(in: .whitespacesAndNewlines)
      let dataPart = lines.removeFirst()
      let event = try parse(eventPart: eventPart, dataPart: dataPart)
      return event
    }
    
    return nil
  }
  
  private func recieved(response: URLResponse, dataTask: URLSessionDataTask) {
    self.response = response
    self.pendingResponse = response
  }
  
  private func completed(error: Error?, task: URLSessionTask) {
    self.pendingError = error
    self.error = error
    self.isCompleted = true
  }
}

extension EventStreamIterator: URLSessionDataDelegate {
  nonisolated
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    Task {
      await self.process(data)
    }
  }

  nonisolated
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse) async -> URLSession.ResponseDisposition {
    Task {
      await recieved(response: response, dataTask: dataTask)
    }
    
    return .allow
  }
  
  nonisolated
  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
    Task {
      await completed(error: error, task: task)
    }
  }
}
