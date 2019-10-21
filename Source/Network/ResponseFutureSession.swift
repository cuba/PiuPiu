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
        self.queue = DispatchQueue(label: "com.jacobsikorski.PiuPiu.ResponseFutureSession")
    }
    
    deinit {
        #if DEBUG
        print("DEINIT - ResponseFutureSession")
        #endif
    }
    
    
    /// Calls urlSession.invalidateAndCancel()
    func invalidateAndCancel() {
        urlSession.invalidateAndCancel()
    }
    
    /// Calls urlSession.finishTasksAndInvalidate()
    func finishTasksAndInvalidate() {
        urlSession.finishTasksAndInvalidate()
    }
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    /// - Returns: The promise that will send the request.
    open func dataFuture(from urlRequest: URLRequest) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { [weak self] future in
            guard let self = self else { return }
            // Create the request and store it internally
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
    
    /// Create a future to make a upload request.
    ///
    /// - Parameters:
    ///   - request: The request to send with data encoded as multpart
    /// - Returns: The promise that will send the request.
    open func uploadFuture(from urlRequest: URLRequest) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { [weak self] future in
            guard let self = self else { return }
            
            // Create the request and store it internally
            let task = self.urlSession.dataTask(with: urlRequest)
            let dataTask = ResponseFutureTask(taskIdentifier: task.taskIdentifier, future: future, urlRequest: urlRequest)
            
            self.queue.sync {
                self.dataTasks.append(dataTask)
                task.resume()
            }
        }
    }
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    ///   - data: The data to send
    /// - Returns: The promise that will send the request.
    func uploadFuture(from urlRequest: URLRequest, data: Data) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { [weak self] future in
            guard let self = self else { return }
            
            // Create the request and store it internally
            let task = self.urlSession.uploadTask(with: urlRequest, from: data)
            let dataTask = ResponseFutureTask(taskIdentifier: task.taskIdentifier, future: future, urlRequest: urlRequest)
            
            self.queue.sync {
                self.dataTasks.append(dataTask)
                task.resume()
            }
        }
    }
    
    private func downloadTask(for task: URLSessionTask, removeTask: Bool) -> ResponseFutureTask<Data?>? {
        var responseFutureTask: ResponseFutureTask<Data?>?
        
        queue.sync {
            responseFutureTask = downloadTasks.first(where: { $0.taskIdentifier == task.taskIdentifier })
            
            if removeTask {
                downloadTasks.removeAll(where: { $0.taskIdentifier == task.taskIdentifier })
            }
        }
        
        return responseFutureTask
    }
    
    private func dataTask(for task: URLSessionTask, removeTask: Bool) -> ResponseFutureTask<Response<Data?>>? {
        queue.sync {
            let responseFutureTask = dataTasks.first(where: { $0.taskIdentifier == task.taskIdentifier })
            
            if removeTask {
                dataTasks.removeAll(where: { $0.taskIdentifier == task.taskIdentifier })
            }
            
            return responseFutureTask
        }
    }
}

// MARK: - Session

extension ResponseFutureSession: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        queue.sync {
            downloadTasks.forEach({ $0.future.cancel() })
            downloadTasks = []
            dataTasks.forEach({ $0.future.cancel() })
            dataTasks = []
        }
    }
}

// MARK: - Task

extension ResponseFutureSession: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let responseFutureTask = self.downloadTask(for: task, removeTask: true) {
            if let error = error ?? responseFutureTask.error {
                responseFutureTask.future.fail(with: error)
            } else {
                responseFutureTask.future.succeed(with: responseFutureTask.data)
            }
        } else if let responseFutureTask = self.dataTask(for: task, removeTask: true) {
            // Ensure we don't have an error
            if let error = error ?? responseFutureTask.error {
                responseFutureTask.future.fail(with: error)
                return
            }
            
            // Ensure there is a http response
            guard let httpResponse = responseFutureTask.response as? HTTPURLResponse else {
                let error = ResponseError.unknown
                responseFutureTask.future.fail(with: error)
                return
            }
            
            // Create the response
            let urlRequest = responseFutureTask.urlRequest
            let statusCode = StatusCode(rawValue: httpResponse.statusCode)
            let response = Response(data: responseFutureTask.data, httpResponse: httpResponse, urlRequest: urlRequest, statusCode: statusCode)
            
            responseFutureTask.future.update(progress: 1)
            responseFutureTask.future.succeed(with: response)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let responseFutureTask = self.dataTask(for: task, removeTask: false) else { return }

        // When an error occurs this value is -1
        guard totalBytesExpectedToSend > 0 else { return }
        let progress = Float(integerLiteral: totalBytesSent) / Float(integerLiteral: totalBytesExpectedToSend)
        
        responseFutureTask.future.update(progress: progress)
    }
}

// MARK: - Data Task

extension ResponseFutureSession: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let responseFutureTask = self.dataTask(for: dataTask, removeTask: false)
        
        // Data is not recieved all at once
        // So we create an empty data set and append the results
        if responseFutureTask?.data == nil {
            responseFutureTask?.data = Data()
        }
        
        // Append data
        responseFutureTask?.data?.append(data)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let responseFutureTask = self.dataTask(for: dataTask, removeTask: false) else {
            completionHandler(.cancel)
            return
        }
        
        responseFutureTask.response = response
        completionHandler(.allow)
    }
}

// MARK: - Download Task

extension ResponseFutureSession: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let responseFutureTask = self.downloadTask(for: downloadTask, removeTask: false) else { return }
        
        do {
            let data = try Data(contentsOf: location)
            responseFutureTask.data = data
        } catch {
            responseFutureTask.error = error
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let responseFutureTask = self.downloadTask(for: downloadTask, removeTask: false) else { return }
        
        // When an error occurs this value is -1
        guard totalBytesExpectedToWrite > 0 else { return }
        
        let progress = Float(integerLiteral: totalBytesWritten) / Float(integerLiteral: totalBytesExpectedToWrite)
        
        responseFutureTask.future.update(progress: progress)
    }
}
