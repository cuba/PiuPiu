//
//  URLSession+Extensions.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-04-23.
//

import Foundation

extension URLSession {
  public func uploadStream(
    with urlRequest: URLRequest,
    fromFile fileURL: URL,
    responseAdapter: URLResponseAdapter? = nil
  ) -> URLRequestStream<URLSessionUploadTask> {
    return self.uploadTask(with: urlRequest, fromFile: fileURL)
      .stream(responseAdapter: responseAdapter)
  }
  
  public func uploadStream(
    with urlRequest: URLRequest,
    from data: Data,
    responseAdapter: URLResponseAdapter? = nil
  ) -> URLRequestStream<URLSessionUploadTask> {
    return self.uploadTask(with: urlRequest, from: data)
      .stream(responseAdapter: responseAdapter)
  }
  
  public func downloadStream(
    with urlRequest: URLRequest,
    from data: Data,
    responseAdapter: URLResponseAdapter? = nil
  ) -> URLRequestStream<URLSessionDownloadTask> {
    return self.downloadTask(with: urlRequest)
      .stream(responseAdapter: responseAdapter)
  }
  
  public func dataStream(
    with urlRequest: URLRequest,
    from data: Data,
    responseAdapter: URLResponseAdapter? = nil
  ) -> URLRequestStream<URLSessionDataTask> {
    return self.dataTask(with: urlRequest)
      .stream(responseAdapter: responseAdapter)
  }
}

