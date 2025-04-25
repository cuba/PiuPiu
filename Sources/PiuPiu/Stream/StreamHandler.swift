//
//  StreamHandler.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-03-21.
//

import Foundation
import os.log

final actor StreamHandler: NSObject {
  struct StreamUpdate: Sendable {
    let data: Data
    let totalBytesSent: Int64
    let totalBytesExpectedToSend: Int64
  }
  
  typealias DataCallback = @Sendable (_ task: URLSessionDataTask, _ data: Data) -> Void
  typealias ResultCallback = @Sendable (_ task: URLSessionTask, _ result: Result<URLResponse, Error>?) -> Void
  
  private let dataReceivedCallback: DataCallback
  private let resultCallback: ResultCallback
  private var response: URLResponse? = nil
  private var error: Error? = nil
  
  init(
    onData: @escaping DataCallback,
    result: @escaping ResultCallback
  ) {
    self.dataReceivedCallback = onData
    self.resultCallback = result
    super.init()
  }
  
  func update(data: Data, dataTask: URLSessionDataTask) {
    Logger.stream.debug("""
      StreamHandler: received \(data.count) bytes
      """)
    dataReceivedCallback(dataTask, data)
  }
  
  func recieved(response: URLResponse, dataTask: URLSessionDataTask) {
    self.response = response
  }
  
  func completed(error: Error?, task: URLSessionTask) {
    if let error {
      resultCallback(task, .failure(error))
    } else if let response {
      resultCallback(task, .success(response))
    } else {
      resultCallback(task, nil)
    }
  }
}

extension StreamHandler: URLSessionDataDelegate {
  nonisolated
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    Task {
      await update(data: data, dataTask: dataTask)
    }
  }

  nonisolated
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse) async -> URLSession.ResponseDisposition {
    Task {
      await recieved(response: response, dataTask: dataTask)
    }
    
    return .allow
  }
  
  nonisolated
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
    Task {
      await completed(error: error, task: task)
    }
  }
}
