//
//  URLSessionTask+Extensions.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-04-23.
//

import Foundation

extension URLSessionUploadTask {
  func stream(responseAdapter: URLResponseAdapter? = nil) -> URLRequestStream<URLSessionUploadTask> {
    URLRequestStream(task: self, responseAdapter: responseAdapter)
  }
}

extension URLSessionDownloadTask {
  func stream(responseAdapter: URLResponseAdapter? = nil) -> URLRequestStream<URLSessionDownloadTask> {
    URLRequestStream(task: self, responseAdapter: responseAdapter)
  }
}

extension URLSessionDataTask {
  func stream(responseAdapter: URLResponseAdapter? = nil) -> URLRequestStream<URLSessionDataTask> {
    URLRequestStream(task: self, responseAdapter: responseAdapter)
  }
}
