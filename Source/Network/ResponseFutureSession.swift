//
//  ResponseFutureSession.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-01.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

class ResponseFutureSession: NSObject {
    let configuration: URLSessionConfiguration
    private var downloadTasks: [ResponseFutureTask<Data?>] = []
    private var dataTasks: [ResponseFutureTask<Response<Data?>>] = []
    private let queue: DispatchQueue
    
    private lazy var urlSession: URLSession = {
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    /// Initialize this `Session` with a `URLSessionConfiguration`.
    ///
    /// - Parameters:
    ///   - configuration: The configuration that will be used to create a `URLSession`.
    public init(configuration: URLSessionConfiguration = .default) {
        self.configuration = configuration
        self.queue = DispatchQueue(label: "com.jacobsikorski.PiuPiu.ResponseFutureSession", attributes: .concurrent)
    }
    
    deinit {
        #if DEBUG
        print("DEINIT - ResponseFutureSession")
        #endif
    }
    
    func invalidateAndCancel() {
        urlSession.invalidateAndCancel()
    }
    
    func finishTasksAndInvalidate() {
        urlSession.finishTasksAndInvalidate()
    }
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - callback: A callback that returns the future to send
    /// - Returns: The promise that will send the request.
    open func dataFuture(from callback: @escaping () throws -> URLRequest) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>> { [weak self] future in
            guard let self = self else { return }
            
            let urlRequest = try callback()
            let nestedFuture = self.dataFuture(from: urlRequest)
            future.fulfill(with: nestedFuture)
        }
    }
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    /// - Returns: The promise that will send the request.
    open func dataFuture(from urlRequest: URLRequest) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { [weak self] future in
            guard let self = self else { return }
            let task = self.urlSession.dataTask(with: urlRequest)
            let dataTask = ResponseFutureTask(taskIdentifier: task.taskIdentifier, future: future, urlRequest: urlRequest)
            
            self.queue.sync {
                self.dataTasks.append(dataTask)
                task.resume()
            }
        }
    }
    
    /// Create a future to make a download request.
    ///
    /// - Parameters:
    ///   - callback: A callback that returns the future to send
    /// - Returns: The promise that will send the request.
    open func downloadFuture(from callback: @escaping () throws -> URLRequest) -> ResponseFuture<Data?> {
        return ResponseFuture<Data?> { [weak self] future in
            guard let self = self else { return }
            let urlRequest = try callback()
            let nestedFuture = self.downloadFuture(from: urlRequest)
            future.fulfill(with: nestedFuture)
        }
    }
    
    /// Create a future to make a download request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    /// - Returns: The promise that will send the request.
    open func downloadFuture(from urlRequest: URLRequest) -> ResponseFuture<Data?> {
        return ResponseFuture<Data?>() { [weak self] future in
            guard let self = self else { return }
            
            // Create the request and store it internally
            let task = self.urlSession.downloadTask(with: urlRequest)
            let downloadTask = ResponseFutureTask(taskIdentifier: task.taskIdentifier, future: future, urlRequest: urlRequest)
            
            self.queue.sync {
                self.downloadTasks.append(downloadTask)
                task.resume()
            }
        }
    }
    
    private func downloadTask(for task: URLSessionTask) -> ResponseFutureTask<Data?>? {
        var responseFutureTask: ResponseFutureTask<Data?>?
        
        queue.sync {
            responseFutureTask = downloadTasks.first(where: { $0.taskIdentifier == task.taskIdentifier })
        }
        
        return responseFutureTask
    }
    
    private func dataTask(for task: URLSessionTask) -> ResponseFutureTask<Response<Data?>>? {
        var responseFutureTask: ResponseFutureTask<Response<Data?>>?
        
        queue.sync {
            responseFutureTask = dataTasks.first(where: { $0.taskIdentifier == task.taskIdentifier })
        }
        
        return responseFutureTask
    }
}

// MARK: - Session

extension ResponseFutureSession: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        queue.sync {
            downloadTasks = []
            dataTasks = []
        }
    }
}

// MARK: - Task

extension ResponseFutureSession: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let responseFutureTask = self.downloadTask(for: task) {
            queue.sync {
                downloadTasks.removeAll(where: { $0.taskIdentifier == task.taskIdentifier })
            }
            
            if let error = error ?? responseFutureTask.error {
                DispatchQueue.main.async {
                    responseFutureTask.future.fail(with: error)
                }
            } else {
                DispatchQueue.main.async {
                    responseFutureTask.future.succeed(with: responseFutureTask.data)
                }
            }
        } else if let responseFutureTask = self.dataTask(for: task) {
            queue.sync {
                dataTasks.removeAll(where: { $0.taskIdentifier == task.taskIdentifier })
            }
            
            // Ensure there is a http response
            guard let httpResponse = responseFutureTask.response as? HTTPURLResponse else {
                let error = ResponseError.unknown(cause: error)
                
                DispatchQueue.main.async {
                    responseFutureTask.future.fail(with: error)
                }
                return
            }
            
            // Create the response
            let urlRequest = responseFutureTask.urlRequest
            let statusCode = StatusCode(rawValue: httpResponse.statusCode)
            let responseError = statusCode.makeError(cause: error)
            let response = Response(data: responseFutureTask.data, httpResponse: httpResponse, urlRequest: urlRequest, statusCode: statusCode, error: responseError)
            
            DispatchQueue.main.async {
                responseFutureTask.future.update(progress: 1)
                responseFutureTask.future.succeed(with: response)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        //let progress = Double(integerLiteral: totalBytesSent) / Double(integerLiteral: totalBytesExpectedToSend)
    }
}

// MARK: - Data Task

extension ResponseFutureSession: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let responseFutureTask = self.dataTask(for: dataTask)
        responseFutureTask?.data = data
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let responseFutureTask = self.dataTask(for: dataTask)
        responseFutureTask?.response = response
    }
}

// MARK: - Download Task

extension ResponseFutureSession: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let responseFutureTask = self.downloadTask(for: downloadTask) else { return }
        
        do {
            let data = try Data(contentsOf: location)
            responseFutureTask.data = data
        } catch {
            responseFutureTask.error = error
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let responseFutureTask = self.downloadTask(for: downloadTask) else { return }
        
        // When an error occurs this value is -1
        guard totalBytesExpectedToWrite > 0 else { return }
        
        let progress = Float(integerLiteral: totalBytesWritten) / Float(integerLiteral: totalBytesExpectedToWrite)
        
        DispatchQueue.main.async {
            responseFutureTask.future.update(progress: progress)
        }
    }
}
