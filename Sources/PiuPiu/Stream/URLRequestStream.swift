//
//  UploadStream.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-04-22.
//

import Foundation
import os.log

protocol TaskTypeProtocol {
  typealias Task = URLSessionTask
  func makeTask(from session: URLSession) -> Task
}

public final class URLRequestStream<SessionTask: URLSessionTask>: AsyncSequence {
  public typealias AsyncIterator = RequestStreamIterator
  public typealias Element = RequestStreamIterator<SessionTask>.Element
  private let task: SessionTask
  /// Use this adapter to transform all responses on this stream
  public weak var responseAdapter: URLResponseAdapter? = nil
  
  init(
    task: SessionTask,
    responseAdapter: URLResponseAdapter? = nil
  ) {
    self.task = task
    self.responseAdapter = responseAdapter
  }
  
  public func makeAsyncIterator() -> RequestStreamIterator<SessionTask> {
    return RequestStreamIterator(task: task, responseAdapter: responseAdapter)
  }
}

public struct UploadProgress {
  let bytesSent: Int64
  let totalBytesSent: Int64
  let totalBytesExpectedToSend: Int64
}

public enum URLRequestStreamEvent<Task: URLSessionTask>: Sendable {
  case taskCreated(Task)
  case uploadProgress(URLSessionTask)
  case downloadProgress(URLSessionTask)
  case response(URLSessionDataTask, Response<URL?>)
  case completed(URLSessionTask)
}

/// An endless sequence iterator for the given resource
public final class RequestStreamIterator<SessionTask: URLSessionTask>: AsyncIteratorProtocol {
  public typealias Element = URLRequestStreamEvent<SessionTask>
  
  private var task: SessionTask
  private var isStarted = false
  private var isCompleted = false
  private let sessionDelegate: RequestStreamSessionDataDelegate
  
  /// Use this adapter to transform all responses on this dispatcher
  public weak var responseAdapter: URLResponseAdapter?
  
  init(
    task: SessionTask,
    responseAdapter: URLResponseAdapter? = nil
  ) {
    self.task = task
    self.responseAdapter = responseAdapter
    self.sessionDelegate = RequestStreamSessionDataDelegate()
    self.task.delegate = sessionDelegate
  }
  
  deinit {
    task.cancel()
  }
  
  public func next() async throws -> URLRequestStreamEvent<SessionTask>? {
    guard isStarted else {
      isStarted = true
      task.resume()
      return .taskCreated(task)
    }
    
    while true {
      if let event = await sessionDelegate.nextEvent() {
        switch event {
        case .uploadProgress(let urlSessionTask):
          return .uploadProgress(urlSessionTask)
        case .downloadProgress(let urlSessionTask):
          return .downloadProgress(urlSessionTask)
        case .response(let task, let urlResponse, let fileURL):
          guard let urlRequest = task.currentRequest ?? self.task.originalRequest else {
            continue
          }
          
          let response = Response<URL?>(
            body: fileURL,
            urlRequest: urlRequest,
            urlResponse: urlResponse
          )
          
          if let responseAdapter {
            return try await .response(
              task,
              response.adapted(with: responseAdapter)
            )
          } else {
            return .response(task, response)
          }
        case .completed(let task, let error):
          isCompleted = true
          
          if let error = error {
            throw error
          } else {
            return .completed(task)
          }
        }
      } else if isCompleted {
        return nil
      }
      
      try await Task.sleep(for: .seconds(0.25))
    }
  }
}

final public actor RequestStreamSessionDataDelegate: NSObject, URLSessionDataDelegate {
  public enum StreamEvent: Sendable {
    case uploadProgress(URLSessionTask)
    case downloadProgress(URLSessionTask)
    case response(URLSessionDataTask, URLResponse, URL?)
    case completed(URLSessionTask, Error?)
  }
  
  var eventQueue: [StreamEvent] = []
  private var fileURL: URL? = nil
  private var fileHandle: FileHandle? = nil
  private var dataTask: URLSessionDataTask? = nil
  private var urlResponse: URLResponse? = nil
  private var error: URLError? = nil
  
  deinit {
    try? fileHandle?.close()
  }
  
  func nextEvent() -> StreamEvent? {
    guard !eventQueue.isEmpty else { return nil }
    return eventQueue.removeFirst()
  }
  
  private func add(event: StreamEvent) {
    Logger.stream.debug("Added event: \(String(describing: event))")
    self.eventQueue.append(event)
  }
  
  private func recieved(response: URLResponse, dataTask: URLSessionDataTask) {
    self.urlResponse = response
    self.dataTask = dataTask
  }
  
  private func completed(error: Error?, task: URLSessionTask) {
    try? self.fileHandle?.close()
    
    if let urlResponse, let dataTask {
      add(event: .response(dataTask, urlResponse, fileURL))
    }
    
    add(event: .completed(dataTask ?? task, error))
  }
  
  private func recieved(data: Data, dataTask: URLSessionDataTask) {
    do {
      let fileHandle = try ensureFileHandle()
      try fileHandle.seekToEnd()
      try fileHandle.write(contentsOf: data)
      add(event: .downloadProgress(dataTask))
    } catch {
      dataTask.cancel()
    }
  }
  
  nonisolated
  public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
    let percent = (Double(totalBytesSent) / Double(totalBytesExpectedToSend)) * 100
    Logger.stream.debug("""
      """)
    
    Logger.stream.debug("""
      bytesSent:                  \(bytesSent)
      totalBytesSent:             \(totalBytesSent)
      countOfBytesSent:           \(task.countOfBytesSent)
      totalBytesExpectedToSend:   \(totalBytesExpectedToSend)
      countOfBytesExpectedToSend: \(task.countOfBytesExpectedToSend)
      percent:                    \(percent)%
      """)
    
    Task {
      await add(event: .uploadProgress(task))
    }
  }
  
  nonisolated
  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
    Task {
      await completed(error: error, task: task)
    }
  }
  
  nonisolated
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    Task {
      await recieved(data: data, dataTask: dataTask)
    }
  }
  
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse) async -> URLSession.ResponseDisposition {
    recieved(response: response, dataTask: dataTask)
    return .allow
  }
  
  private func ensureFileHandle() throws -> FileHandle {
    if let fileHandle { return fileHandle }
    let fileURL = try createNewDownloadFile()
    let fileHandle = try FileHandle(forWritingTo: fileURL)
    self.fileURL = fileURL
    self.fileHandle = fileHandle
    return fileHandle
  }
  
  private func ensureTempDirectory() throws -> URL {
    let downloadDirectory = URL.temporaryDirectory.appending(path: "piupiu")
    if !FileManager.default.fileExists(atPath: downloadDirectory.path(percentEncoded: false)) {
      try FileManager.default.createDirectory(at: downloadDirectory, withIntermediateDirectories: false)
    }
    return downloadDirectory
  }
  
  private func createNewDownloadFile() throws -> URL {
    let downloadDirectoryURL = try ensureTempDirectory()
    let fileURL = downloadDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("tmp")
    FileManager.default.createFile(atPath: fileURL.path(percentEncoded: false), contents: nil)
    return fileURL
  }
}
