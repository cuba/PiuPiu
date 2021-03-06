//
//  ResponseFutureSession.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-01.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

open class ResponseFutureSession: NSObject {
    let configuration: URLSessionConfiguration
    private var downloadTasks: [ResponseFutureTask<URL>] = []
    private var dataTasks: [ResponseFutureTask<Data?>] = []
    private let queue: DispatchQueue
    private var downloadedFiles: [URL] = []
    
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
        let task = self.urlSession.dataTask(with: urlRequest)
        return dataFuture(from: task)
    }
    
    /// Create a future to make a data request using a data task.
    ///
    /// - Parameters:
    ///   - request: The task to execute
    /// - Returns: The promise that will send the request.
    open func dataFuture(from task: URLSessionDataTask) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { [weak self] future in
            guard let self = self else { return }
            future.update(with: task)
            
            // Create the request and store it internally
            let dataTask = ResponseFutureTask<Data?>(taskIdentifier: task.taskIdentifier, future: future)
            
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
    ///   - destination: The location to store the downloaded file in
    /// - Returns: The promise that will send the request.
    open func downloadFuture(from urlRequest: URLRequest, to destination: URL) -> ResponseFuture<Response<URL>> {
        let task = self.urlSession.downloadTask(with: urlRequest)
        return downloadFuture(from: task, to: destination)
    }
    
    /// Create a future to make a download request.
    ///
    /// - Parameters:
    ///   - task: The download task to perform
    ///   - destination: The location to store the downloaded file in
    /// - Returns: The promise that will send the request.
    open func downloadFuture(from task: URLSessionDownloadTask, to destination: URL) -> ResponseFuture<Response<URL>> {
        return ResponseFuture<Response<URL>>() { [weak self] future in
            guard let self = self else { return }
            future.update(with: task)
            
            // Create the request and store it internally
            let downloadTask = ResponseFutureTask<URL>(taskIdentifier: task.taskIdentifier, future: future, destination: destination)
            
            self.queue.sync {
                self.downloadTasks.append(downloadTask)
                task.resume()
            }
        }
    }
    
    /// Create a future to make a upload request using data.
    ///
    /// - Parameters:
    ///   - request: The request to send
    ///   - data: The data to include in the request
    /// - Returns: The promise that will send the request.
    open func uploadFuture(from urlRequest: URLRequest, with data: Data) -> ResponseFuture<Response<Data?>> {
        let task = self.urlSession.uploadTask(with: urlRequest, from: data)
        return uploadFuture(from: task)
    }
    
    /// Create a future to make a data request.
    ///
    /// - Parameters:
    ///   - request: The request to send
    ///   - url: The file url to send
    /// - Returns: The promise that will send the request.
    func uploadFuture(from urlRequest: URLRequest, withFile url: URL) -> ResponseFuture<Response<Data?>> {
        let task = self.urlSession.uploadTask(with: urlRequest, fromFile: url)
        return uploadFuture(from: task)
    }
    
    /// Create a future to make a upload request.
    ///
    /// - Parameters:
    ///   - request: The request to send with data encoded as multpart
    /// - Returns: The promise that will send the request.
    open func uploadFuture(from task: URLSessionUploadTask) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { [weak self] future in
            guard let self = self else { return }
            future.update(with: task)
            
            // Create the request and store it internally
            let dataTask = ResponseFutureTask<Data?>(taskIdentifier: task.taskIdentifier, future: future)
            
            self.queue.sync {
                self.dataTasks.append(dataTask)
                task.resume()
            }
        }
    }
    
    private func downloadTask(for task: URLSessionTask, removeTask: Bool) -> ResponseFutureTask<URL>? {
        var responseFutureTask: ResponseFutureTask<URL>?
        
        queue.sync {
            responseFutureTask = downloadTasks.first(where: { $0.taskIdentifier == task.taskIdentifier })
            
            if removeTask {
                downloadTasks.removeAll(where: { $0.taskIdentifier == task.taskIdentifier })
            }
        }
        
        return responseFutureTask
    }
    
    private func dataTask(for task: URLSessionTask, removeTask: Bool) -> ResponseFutureTask<Data?>? {
        var responseFutureTask: ResponseFutureTask<Data?>?
        
        queue.sync {
            responseFutureTask = dataTasks.first(where: { $0.taskIdentifier == task.taskIdentifier })
            
            if removeTask {
                dataTasks.removeAll(where: { $0.taskIdentifier == task.taskIdentifier })
            }
        }
        
        return responseFutureTask
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
        if let responseFutureTask = self.dataTask(for: task, removeTask: true) {
            // Ensure we don't have an error
            if let error = error ?? responseFutureTask.error {
                responseFutureTask.future.fail(with: error)
                return
            }
            
            // Ensure there is a http response
            guard let urlResponse = task.response else {
                responseFutureTask.future.fail(with: ResponseError.noResponse)
                return
            }
            
            // Create the response
            guard let urlRequest = task.currentRequest ?? task.originalRequest else {
                return
            }
            
            let response = Response(data: responseFutureTask.data, urlRequest: urlRequest, urlResponse: urlResponse)
            
            responseFutureTask.future.succeed(with: response)
        } else if let responseFutureTask = self.downloadTask(for: task, removeTask: true) {
            guard let error = error else {
                assertionFailure("The task should have been removed already!")
                return
            }
            
            responseFutureTask.future.fail(with: error)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let responseFutureTask = self.dataTask(for: task, removeTask: false) else { return }
        responseFutureTask.future.update(with: task)
    }
}

// MARK: - Data Task

extension ResponseFutureSession: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let responseFutureTask = self.dataTask(for: dataTask, removeTask: false)
        responseFutureTask?.future.update(with: dataTask)
        
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
        
        responseFutureTask.future.update(with: dataTask)
        completionHandler(.allow)
    }
}

// MARK: - Download Task

extension ResponseFutureSession: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let responseFutureTask = self.downloadTask(for: downloadTask, removeTask: true) else { return }
        responseFutureTask.future.update(with: downloadTask)
        
        // Ensure there is a http response
        guard let urlResponse = downloadTask.response else {
            responseFutureTask.future.fail(with: ResponseError.noResponse)
            return
        }
        
        // Create the response
        guard let urlRequest = downloadTask.currentRequest ?? downloadTask.originalRequest else {
            return
        }
        
        guard let destination = responseFutureTask.destination else {
            preconditionFailure("You need to set a destination")
        }
        
        #if DEBUG
        print("Moving file from `\(location.absoluteString)` to `\(destination.absoluteString)`")
        #endif
        
        // Save the file somewhere else
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            
            try FileManager.default.copyItem(at: location, to: destination)
            
            let response = Response(data: destination, urlRequest: urlRequest, urlResponse: urlResponse)
            responseFutureTask.future.succeed(with: response)
        } catch {
            responseFutureTask.future.fail(with: error)
            return
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let responseFutureTask = self.downloadTask(for: downloadTask, removeTask: false) else { return }
        responseFutureTask.future.update(with: downloadTask)
    }
}
