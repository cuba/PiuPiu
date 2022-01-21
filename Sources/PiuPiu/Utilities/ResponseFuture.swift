//
//  ResponseFuture.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-02-15.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A ResponseFuture is a delayed action that is performed after calling `start()`.
public class ResponseFuture<Success> {
    public typealias ActionCallback = (ResponseFuture<Success>) throws -> Void
    public typealias SuccessHandler = (Success) throws -> Void
    public typealias ErrorHandler = (Error) -> Void
    public typealias CompletionHandler = () -> Void
    public typealias TaskCallback = (URLSessionTask) -> Void
    public typealias CancellationHandler = () -> Void
    
    public enum Status {
        case created
        case started
        case success
        case error
        case cancelled
        
        var isComplete: Bool {
            switch self {
            case .created   : return false
            case .started   : return false
            case .success   : return true
            case .error     : return true
            case .cancelled : return true
            }
        }
    }
    
    private var action: ActionCallback?
    private var successHandler: SuccessHandler?
    private var errorHandler: ErrorHandler?
    private var completionHandler: CompletionHandler?
    private var taskCallback: TaskCallback?
    private var cancellationHandler: CancellationHandler?
    
    /// The status of the future.
    private(set) public var status: Status
    
    /// Initialize the future with an action that is triggered when calling the start() method.
    ///
    /// - Parameter action: The action that is performed. The action returns this future when triggered.
    public init(action: @escaping ActionCallback) {
        self.action = action
        self.status = .created
    }
    
    /// Initialize the future with an result that triggers the success callback as soon as `send` or `start` is called.
    ///
    /// - Parameter result: The result that is returned right away.
    public convenience init(result: Success) {
        self.init { future in
            future.succeed(with: result)
        }
    }
    
    /// Fulfills the given future with the results of this future. Both futures have to be of the same type.
    ///
    /// - Parameter future: The future to be fulfilled.
    public func fulfill(_ future: ResponseFuture<Success>) {
        self.success { result in
            future.succeed(with: result)
        }
        .updated { task in
            future.update(with: task)
        }
        .error { error in
            future.fail(with: error)
        }
        .send()
    }
    
    /// Fulfills this future with the results of the given future. Both futures have to be of the same type.
    ///
    /// - Parameter future: The future to be fulfilled.
    @available(*, deprecated, message: "Reverse the roles and use `fulfill(:ResponseFuture)` instead.")
    public func fulfill(by future: ResponseFuture<Success>) {
        future.fulfill(self)
    }
    
    /// Fulfills this future with the results of the given future. Both futures have to be of the same type.
    ///
    /// - Parameter future: The future to be fulfilled.
    @available(*, deprecated, message: "Reverse the roles and use `fulfill(:ResponseFuture)` instead.")
    public func fulfill(with future: ResponseFuture<Success>) {
        future.fulfill(self)
    }
    
    /// Fullfill this future with a successful result.
    ///
    /// - Parameter object: The succeeded object required by the future success callback.
    public func succeed(with object: Success) {
        DispatchQueue.main.async {
            do {
                try self.successHandler?(object)
                self.status = .success
                self.completionHandler?()
                self.finalize()
            } catch {
                self.fail(with: error)
            }
        }
    }
    
    /// Fullfill the future with a failed result.
    ///
    /// - Parameter object: The failed object required by the future error callback.
    public func fail(with error: Error) {
        DispatchQueue.main.async {
            self.errorHandler?(error)
            self.status = .error
            self.completionHandler?()
            self.finalize()
        }
    }

    /// Complete this future with the given results
    public func complete(with result: Result<Success, Error>) {
        switch result {
        case .success(let success):
            succeed(with: success)
        case .failure(let error):
            fail(with: error)
        }
    }
    
    /// Cancel this future. The cancellation and completion callbacks will be triggered on this future and no further callbacks will be triggered. This method does not cancel the URLSessionTask itself. When manually creating a wrapped ResponseFuture, you need to make sure you call cancel on the new future to continue the cancellation chain.
    public func cancel() {
        DispatchQueue.main.async {
            self.cancellationHandler?()
            self.status = .cancelled
            self.completionHandler?()
            self.finalize()
        }
    }
    
    /// Clears all callbacks to avoid memory leaks
    private func finalize() {
        action = nil
        successHandler = nil
        errorHandler = nil
        taskCallback = nil
        cancellationHandler = nil
    }
    
    /// Update the progress of this future.
    ///
    /// - Parameter progress: The progress of this future between 0 and 1 where 0 is 0% and 1 being 100%
    public func update(with task: URLSessionTask) {
        DispatchQueue.main.async {
            self.taskCallback?(task)
        }
    }
    
    /// Attach a success handler to this future. Should be called before the `start()` method in case the future is fulfilled synchronously.
    ///
    /// - Parameter handler: The success handler that will be trigged after the `succeed()` method is called.
    /// - Returns: This future for chaining.
    public func updated(_ callback: @escaping TaskCallback) -> ResponseFuture<Success> {
        self.taskCallback = callback
        return self
    }
    
    /// Attach a success handler to this future. Should be called before the `start()` method in case the future is fulfilled synchronously.
    /// **DO NOT** use `result` callback in conjunction with this callback.
    ///
    /// - Parameter handler: The success handler that will be trigged after the `succeed()` method is called.
    /// - Returns: This future for chaining.
    public func success(_ handler: @escaping SuccessHandler) -> ResponseFuture<Success> {
        self.successHandler = handler
        return self
    }
    
    /// Attach a success handler to this future. Should be called before the `start()` method in case the future is fulfilled synchronously.
    /// **DO NOT** use `success` or `result` callbacks in conjunction with this callback.
    ///
    /// - Parameter handler: The success handler that will be trigged after the `succeed()` method is called.
    /// - Returns: This future for chaining.
    @available(*, deprecated, renamed: "success")
    public func response(_ handler: @escaping SuccessHandler) -> ResponseFuture<Success> {
        return success(handler)
    }
    
    /// Attach an error handler to this future that handles . Should be called before the `start()` method in case the future is fulfilled synchronously.
    /// **DO NOT** use `result` callback in conjunction with this callback.
    ///
    /// - Parameter handler: The error handler that will be triggered if anything is thrown inside the success callback.
    /// - Returns: This future for chaining.
    public func error(_ handler: @escaping ErrorHandler) -> ResponseFuture<Success> {
        self.errorHandler = handler
        return self
    }
    
    /// Attach a completion handler to this future. Should be called before the `start()` method in case the future is fulfilled synchronously.
    ///
    /// - Parameter handler: The completion handler that will be triggered after the `succeed()` or `fail()` methods are triggered.
    /// - Returns: This future for chaining.
    public func completion(_ handler: @escaping CompletionHandler) -> ResponseFuture<Success> {
        self.completionHandler = handler
        return self
    }
    
    /// Attach a completion handler to this future. Should be called before the `start()` method in case the future is fulfilled synchronously.
    ///
    /// - Parameter handler: The completion handler that will be triggered after the `succeed()` or `fail()` methods are triggered.
    /// - Returns: This future for chaining.
    public func cancellation(_ handler: @escaping CancellationHandler) -> ResponseFuture<Success> {
        self.cancellationHandler = handler
        return self
    }
    
    /// Attach a result handler to this future. Should be called before the `start()` method in case the future is fulfilled synchronously.
    /// **DO NOT** use `success` or `error` callbacks in conjunction with this callback.
    ///
    /// - Parameter handler: The completion handler that will be triggered after the `succeed()` or `fail()` methods are triggered.
    /// - Returns: This future for chaining.
    public func result(_ handler: @escaping (Result<Success, Error>) -> Void) -> ResponseFuture<Success> {
        self.success { response in
            handler(.success(response))
        }.error { error in
            handler(.failure(error))
        }
    }
    
    /// Convert the success callback to another type.
    /// Returning nil on the callback will cause a the cancellation callback to be triggered.
    /// NOTE: You should not be updating anything on UI from this thread. To be safe avoid calling self on the callback.
    ///
    /// - Parameters:
    ///   - queue: The queue to run the callback on. The default is the main thread.
    ///   - callback: The callback to perform the transformation
    /// - Returns: The transformed future
    public func map<U>(_ type: U.Type, on queue: DispatchQueue = DispatchQueue.main, successCallback: @escaping (Success) throws -> U) -> ResponseFuture<U> {
        return ResponseFuture<U> { future in
            self.success { result in
                queue.async {
                    do {
                        let transformed = try successCallback(result)
                        future.succeed(with: transformed)
                    } catch {
                        future.fail(with: error)
                    }
                }
            }
            .updated { task in
                future.update(with: task)
            }
            .error { error in
                future.fail(with: error)
            }
            .cancellation {
                future.cancel()
            }
            .send()
        }
        
    }
    
    /// Convert the success callback to another type.
    /// Returning nil on the callback will cause a the cancellation callback to be triggered.
    /// NOTE: You should not be updating anything on UI from this thread. To be safe avoid calling self on the callback.
    ///
    /// - Parameters:
    ///   - queue: The queue to run the callback on. The default is the main thread.
    ///   - callback: The callback to perform the transformation
    /// - Returns: The transformed future
    public func then<U>(on queue: DispatchQueue = DispatchQueue.main, _ successCallback: @escaping (Success) throws -> U) -> ResponseFuture<U> {
        return map(U.self, on: queue, successCallback: successCallback)
    }
    
    /// Convert the success callback to another type.
    /// Returning nil on the callback will cause a the cancellation callback to be triggered.
    /// NOTE: You should not be updating anything on UI from this thread. To be safe avoid calling self on the callback.
    ///
    /// - Parameters:
    ///   - queue: The queue to run the callback on. The default is the main thread.
    ///   - callback: The callback to perform the transformation
    /// - Returns: The transformed future
    public func then<U>(_ type: U.Type, on queue: DispatchQueue = DispatchQueue.main, _ successCallback: @escaping (Success) throws -> U) -> ResponseFuture<U> {
        return map(type, on: queue, successCallback: successCallback)
    }
    
    /// Allows the error to fail by returning a success response with either the original response or the error
    ///
    /// - Returns: A new future containing the original response or an error object.
    public func thenResult<U>(_ type: U.Type, callback: @escaping (Result<Success, Error>) throws -> U) -> ResponseFuture<U> {
        return ResponseFuture<U> { future in
            self.success { response in
                let callbackResult = try callback(.success(response))
                future.succeed(with: callbackResult)
            }
            .error { error in
                do {
                    let callbackResult = try callback(.failure(error))
                    future.succeed(with: callbackResult)
                } catch let newError {
                    future.fail(with: newError)
                }
            }
            .updated { task in
                future.update(with: task)
            }
            .cancellation {
                future.cancel()
            }
            .send()
        }
    }
    
    /// Allows the error to fail by returning a success response with either the original response or the error
    ///
    /// - Returns: A new future containing the original response or an error object.
    public func safeResult() -> ResponseFuture<Result<Success, Error>> {
        return ResponseFuture<Result<Success, Error>>() { future in
            self.success { response in
                future.succeed(with: .success(response))
            }
            .error { error in
                future.succeed(with: .failure(error))
            }
            .updated{ task in
                future.update(with: task)
            }
            .send()
        }
    }
    
    /// Return a new future with the results of both futures making both calls in series
    /// WARNING: Returning `nil` on the callback will cause all the requests to be cancelled and the cancellation callback to be triggered.
    ///
    /// - Parameter callback: The future that returns the results we want to return.
    /// - Returns: A new response future that will contain the results
    public func replace<U>(_ type: U.Type, callback: @escaping (Success) throws -> ResponseFuture<U>?) -> ResponseFuture<U> {
        return ResponseFuture<U> { future in
            self.success { response in
                guard let newPromise = try callback(response) else {
                    future.cancel()
                    return
                }
                
                newPromise.success { newResponse in
                    future.succeed(with: newResponse)
                }
                .updated { task in
                    future.update(with: task)
                }
                .error { error in
                    future.fail(with: error)
                }
                .cancellation {
                    future.cancel()
                }
                .send()
            }
            .error { error in
                future.fail(with: error)
            }
            .updated { task in
                future.update(with: task)
            }
            .cancellation {
                future.cancel()
            }
            .send()
        }
    }
    
    /// Return a new future with the results of both futures making both calls in parallel
    /// WARNING: Returning `nil` on the callback will cause all the requests to be cancelled and the cancellation callback to be triggered.
    ///
    /// - Parameter callback: The callback that contains the results of the original future
    /// - Returns: A new future with the results of both futures
    public func seriesJoin<U>(_ type: U.Type, callback: @escaping (Success) throws -> ResponseFuture<U>?) -> ResponseFuture<(Success, U)> {
        return ResponseFuture<(Success, U)> { future in
            self.success { response in
                guard let newFuture = try callback(response) else {
                    future.cancel()
                    return
                }
                
                newFuture.success { newResponse in
                    future.succeed(with: (response, newResponse))
                }
                .error { error in
                    future.fail(with: error)
                }
                .updated { task in
                    future.update(with: task)
                }
                .cancellation {
                    future.cancel()
                }
                .send()
            }
            .error { error in
                future.fail(with: error)
            }
            .updated { task in
                future.update(with: task)
            }
            .cancellation {
                future.cancel()
            }
            .send()
        }
    }
    
    /// Return a new future with the results of both futures making both calls in parallel
    ///
    /// - Parameter callback: The future that returns the results we want to return.
    /// - Returns: The new future with both responses
    public func parallelJoin<U>(_ type: U.Type, callback: () -> ResponseFuture<U>) -> ResponseFuture<(Success, U)> {
        let newFuture = callback()
        
        return ResponseFuture<(Success, U)> { future in
            var firstResult: Result<Success, Error>?
            var secondResult: Result<U, Error>?
            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter()
            self.result { result in
                firstResult = result
            }
            .updated { task in
                future.update(with: task)
            }
            .completion {
                dispatchGroup.leave()
            }
            .send()
            
            dispatchGroup.enter()
            newFuture.result { result in
                secondResult = result
            }
            .updated { task in
                future.update(with: task)
            }
            .completion {
                dispatchGroup.leave()
            }
            .send()
            
            dispatchGroup.notify(queue: .main) {
                guard let firstResult = firstResult, let secondResult = secondResult else {
                    // The only way that neither is returned is one or the other was cancelled
                    future.cancel()
                    return
                }
                
                switch (firstResult, secondResult) {
                case (.success(let first), .success(let second)):
                    future.succeed(with: (first, second))
                case (.failure(let error), .success):
                    future.fail(with: error)
                case (.success, .failure(let error)):
                    future.fail(with: error)
                case (.failure(let error), .failure):
                    future.fail(with: error)
                }
            }
        }
    }
    
    /// Return a new future with the results of both futures making both calls in series
    /// Returning `nil` on the callback does **not** cancel the requests
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func seriesNullableJoin<U>(_ type: U.Type, callback: @escaping (Success) throws -> ResponseFuture<U>?) -> ResponseFuture<(Success, U?)> {
        return ResponseFuture<(Success, U?)> { future in
            self.success { response in
                guard let newFuture = try callback(response) else {
                    future.succeed(with: (response, nil))
                    return
                }
                
                newFuture.success { newResponse in
                    future.succeed(with: (response, newResponse))
                }
                .error { error in
                    future.fail(with: error)
                }
                .updated { task in
                    future.update(with: task)
                }
                .cancellation {
                    future.cancel()
                }
                .send()
            }.error { error in
                future.fail(with: error)
            }
            .updated { task in
                future.update(with: task)
            }
            .cancellation {
                future.cancel()
            }
            .send()
        }
    }
    
    /// Return a new future with the results of both futures making both calls in parallel
    /// Returning `nil` on the callback does **not** cancel the requests
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func parallelNullableJoin<U>(_ type: U.Type, callback: () -> ResponseFuture<U>?) -> ResponseFuture<(Success, U?)> {
        if let future = callback() {
            return parallelJoin(type) {
                return future
            }.then((Success, U?).self) { result in
                return (result.0, result.1 as U?)
            }
        } else {
            return then((Success, U?).self) { result in
                return (result, nil)
            }
        }
    }
    
    /// Return a new future with the results of both futures making both calls in series
    /// WARNING: Returning `nil` on the callback will cause all the requests to be cancelled and the cancellation callback to be triggered.
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func safeSeriesJoin<U>(_ type: U.Type, callback: @escaping (Success) throws -> ResponseFuture<U>?) -> ResponseFuture<(Success, Result<U, Error>)> {
        return seriesJoin(Result<U, Error>.self) { result in
            return try callback(result)?.safeResult()
        }
    }
    
    /// Return a new future with the results of both futures making both calls in parallel
    /// Returning `nil` on the callback does **not** cancel the requests
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func safeParallelJoin<U>(_ type: U.Type, callback: () -> ResponseFuture<U>) -> ResponseFuture<(Success, Result<U, Error>)> {
        return parallelJoin(Result<U, Error>.self, callback: {
            return callback().safeResult()
        })
    }
    
    /// Return a new future with the results of both futures making both calls in parallel
    /// Returning `nil` on the callback does **not** cancel the requests
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func safeSeriesNullableJoin<U>(_ type: U.Type, callback: @escaping (Success) throws -> ResponseFuture<U>?) -> ResponseFuture<(Success, Result<U, Error>?)> {
        return seriesNullableJoin(Result<U, Error>.self) { result in
            return try callback(result)?.safeResult()
        }
    }
    
    /// Return a new future with the results of both futures making both calls in series
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func safeParallelNullableJoin<U>(_ type: U.Type, callback: () -> ResponseFuture<U>?) -> ResponseFuture<(Success, Result<U, Error>?)> {
        return parallelNullableJoin(Result<U, Error>.self) {
            return callback()?.safeResult()
        }
    }
    
    /// This method triggers the action method defined on this future.
    public func start() {
        self.status = .started
        
        do {
            try action?(self)
            action = nil
        } catch {
            fail(with: error)
        }
    }
    
    /// This method triggers the action method defined on this future.
    public func send() {
        start()
    }

    /// Return an async result
    @available(iOS 13.0.0, *)
    public func fetchResult() async throws -> Success {
        let continuationResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Success, Error>) in
            self.result { result in
                continuation.resume(with: result)
            }
            .start()
        }
        
        return continuationResult
    }
} 

public extension ResponseFuture where Success: Sequence {
    convenience init(childFuturesCallback: () -> [ResponseFuture<Success.Element>]) {
        self.init(childFutures: childFuturesCallback())
    }
    
    convenience init(arrayLiteral futures: ResponseFuture<Success.Element>...) {
        self.init(childFutures: futures)
    }
    
    convenience init(childFutures: [ResponseFuture<Success.Element>]) {
        self.init { future in
            var results = [Result<Success.Element, Error>?](repeating: nil, count: childFutures.count)
            let dispatchGroup = DispatchGroup()
            
            for (futureIndex, childFuture) in childFutures.enumerated() {
                dispatchGroup.enter()
                
                childFuture
                    .result { result in
                        results[futureIndex] = result
                    }
                    .updated { task in
                        future.update(with: task)
                    }
                    .completion {
                        dispatchGroup.leave()
                    }
                    .send()
            }
            
            dispatchGroup.notify(queue: .main) {
                var elements: [Success.Element] = []
                
                for result in results {
                    guard let result = result else {
                        // This shouldn't happen
                        continue
                    }
                    
                    switch result {
                    case .success(let element):
                        elements.append(element)
                    case .failure(let error):
                        future.fail(with: error)
                        return
                    }
                }
                
                future.succeed(with: elements as! Success)
            }
        }
    }
    
    /// Conveniently call a  future in series and append its results into this future where the result of the future is a sequence and the result of the given future is an element of that sequence.
    /// WARNING: Returning `nil` on the callback will cause all the requests to be cancelled and the cancellation callback to be triggered.
    func addingSeriesResult(from callback: @escaping (Success) throws -> ResponseFuture<Success.Element>?) -> ResponseFuture<[Success.Element]> {
        return seriesJoin(Success.Element.self, callback: callback)
            .map([Success.Element].self) { (sequence, element) in
                var result = Array(sequence)
                result.append(element)
                return result
            }
    }
}

public extension ResponseFuture where Success == Response<Data?> {
    func makeHTTPResponse() -> ResponseFuture<HTTPResponse<Data?>> {
        return then(HTTPResponse<Data?>.self, on: DispatchQueue.global(qos: .background)) { response -> HTTPResponse<Data?> in
            return try response.makeHTTPResponse()
        }
    }
    
    /// This method returns an HTTP response containing a decoded object
    func decoded<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) -> ResponseFuture<Response<D>> {
        return then(Response<D>.self, on: DispatchQueue.global(qos: .background)) { response -> Response<D> in
            return try response.decoded(type, using: decoder)
        }
    }

    /// This method returns an HTTP response containing a string
    func decodedString() -> ResponseFuture<Response<String>> {
        return then(Response<String>.self, on: DispatchQueue.global(qos: .background)) { response -> Response<String> in
            let data = try response.decodeString()
            return Response(data: data, urlRequest: response.urlRequest, urlResponse: response.urlResponse)
        }
    }
}

public extension ResponseFuture where Success == HTTPResponse<Data?> {
    /// This method returns an HTTP response containing a decoded object
    func decoded<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) -> ResponseFuture<HTTPResponse<D>> {
        return then(HTTPResponse<D>.self, on: DispatchQueue.global(qos: .background)) { httpResponse -> HTTPResponse<D> in
            return try httpResponse.decoded(type, using: decoder)
        }
    }
    
    /// This method returns an `HTTPResponse` containing a result with either the decoded object or an error that occured during decoding.
    /// This is useful because we may need to do a safe decoding but we don't care for any other errors
    func safeDecoded<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) -> ResponseFuture<HTTPResponse<Result<D, Error>>> {
        return ResponseFuture<HTTPResponse<Result<D, Error>>> { future in
            self
                .success { response in
                    do {
                        let decoded = try response.decoded(type, using: decoder)
                        let newResponse = try HTTPResponse<Result<D, Error>>(response: response, data: .success(decoded.data))
                        future.succeed(with: newResponse)
                    } catch {
                        let newResponse = try HTTPResponse<Result<D, Error>>(response: response, data: .failure(error))
                        future.succeed(with: newResponse)
                    }
                }
                .error { error in
                    future.fail(with: error)
                }
                .updated{ task in
                    future.update(with: task)
                }
                .send()
        }
    }
}
