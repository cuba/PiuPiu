//
//  ResponseFuture.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-02-15.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A ResponseFuture is a delayed action that is performed after calling `start()`.
public class ResponseFuture<T> {
    public typealias ActionCallback = (ResponseFuture<T>) throws -> Void
    public typealias SuccessHandler = (T) throws -> Void
    public typealias ErrorHandler = (Error) -> Void
    public typealias CompletionHandler = () -> Void
    public typealias ProgressCallback = (Float) -> Void
    
    public enum Status {
        case created
        case started
        case success
        case error
        
        var isComplete: Bool {
            switch self {
            case .created   : return false
            case .started   : return false
            case .success   : return true
            case .error     : return true
            }
        }
    }
    
    private var action: ActionCallback?
    private var successHandler: SuccessHandler?
    private var errorHandler: ErrorHandler?
    private var completionHandler: CompletionHandler?
    private var progressCallback: ProgressCallback?
    private let order: Int
    
    /// The status of the promise.
    private(set) public var status: Status
    
    /// Initialize the promise with an action that is triggered when calling the start() method.
    ///
    /// - Parameter action: The action that is performed. The action returns this promise when triggered.
    public init(order: Int = 1, action: @escaping ActionCallback) {
        self.action = action
        self.status = .created
        self.order = order
    }
    
    /// Initialize the promise with an result that triggers the success callback as soon as `send` or `start` is called.
    ///
    /// - Parameter result: The result that is returned right away.
    public convenience init(order: Int = 1, result: T) {
        self.init(order: order) { future in
            future.succeed(with: result)
        }
    }
    
    /// Fulfills the given promise with the results of the given promise. Both promises have to be of the same type.
    ///
    /// - Parameter promise: The promise to be fulfilled.
    public func fulfill(_ future: ResponseFuture<T>) {
        self.success({ result in
            future.succeed(with: result)
        }).progress({ progress in
            future.update(progress: progress)
        }).error({ error in
            future.fail(with: error)
        }).send()
    }
    
    /// Fulfills the given promise with the results of the given promise. Both promises have to be of the same type.
    ///
    /// - Parameter promise: The promise to be fulfilled.
    public func fulfill(with promise: ResponseFuture<T>) {
        promise.success({ result in
            self.succeed(with: result)
        }).progress({ progress in
            self.update(progress: progress)
        }).error({ error in
            self.fail(with: error)
        }).send()
    }
    
    /// Fullfill this promise with a successful result.
    ///
    /// - Parameter object: The succeeded object required by the promise success callback.
    public func succeed(with object: T) {
        do {
            try successHandler?(object)
            status = .success
            completionHandler?()
            
            // Clear all callbacks to avoid memory leaks
            action = nil
            successHandler = nil
            errorHandler = nil
            progressCallback = nil
        } catch {
            self.fail(with: error)
        }
    }
    
    /// Fullfill the promise with a failed result.
    ///
    /// - Parameter object: The failed object required by the promise error callback.
    public func fail(with error: Error) {
        errorHandler?(error)
        status = .error
        completionHandler?()
        
        // Clear all callbacks to avoid memory leaks
        action = nil
        successHandler = nil
        errorHandler = nil
        progressCallback = nil
    }
    
    public func update(progress: Float) {
        progressCallback?(progress)
    }
    
    /// Attach a success handler to this promise. Should be called before the `start()` method in case the promise is fulfilled synchronously.
    ///
    /// - Parameter handler: The success handler that will be trigged after the `succeed()` method is called.
    /// - Returns: This promise for chaining.
    public func progress(_ callback: @escaping ProgressCallback) -> ResponseFuture<T> {
        self.progressCallback = callback
        return self
    }
    
    /// Attach a success handler to this promise. Should be called before the `start()` method in case the promise is fulfilled synchronously.
    ///
    /// - Parameter handler: The success handler that will be trigged after the `succeed()` method is called.
    /// - Returns: This promise for chaining.
    public func success(_ handler: @escaping SuccessHandler) -> ResponseFuture<T> {
        self.successHandler = handler
        return self
    }
    
    /// Attach a success handler to this promise. Should be called before the `start()` method in case the promise is fulfilled synchronously.
    ///
    /// - Parameter handler: The success handler that will be trigged after the `succeed()` method is called.
    /// - Returns: This promise for chaining.
    public func response(_ handler: @escaping SuccessHandler) -> ResponseFuture<T> {
        return success(handler)
    }
    
    /// Attach a error handler to this promise that handles . Should be called before the `start()` method in case the promise is fulfilled synchronously.
    ///
    /// - Parameter handler: The error handler that will be triggered if anything is thrown inside the success callback.
    /// - Returns: This promise for chaining.
    public func error(_ handler: @escaping ErrorHandler) -> ResponseFuture<T> {
        self.errorHandler = handler
        return self
    }
    
    /// Attach a completion handler to this promise. Should be called before the `start()` method in case the promise is fulfilled synchronously.
    ///
    /// - Parameter handler: The completion handler that will be triggered after the `succeed()` or `fail()` methods are triggered.
    /// - Returns: This promise for chaining.
    public func completion(_ handler: @escaping CompletionHandler) -> ResponseFuture<T> {
        self.completionHandler = handler
        return self
    }
    
    /// Convert the success callback to another type.
    /// NOTE: You should not be updating anything on UI from this thread. To be safe avoid calling self on the callback.
    ///
    /// - Parameters:
    ///   - queue: The queue to run the callback on. The default is a background thread.
    ///   - callback: The callback to perform the transformation
    /// - Returns: The transformed promise
    public func then<U>(on queue: DispatchQueue = DispatchQueue.global(qos: .background), _ callback: @escaping (T) throws -> U) -> ResponseFuture<U> {
        return ResponseFuture<U>(order: order + 1) { future in
            self.success({ result in
                queue.async {
                    do {
                        let transformed = try callback(result)
                        
                        DispatchQueue.main.async {
                            future.succeed(with: transformed)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            future.fail(with: error)
                        }
                    }
                }
            }).progress({ progress in
                future.update(progress: progress)
            }).error({ error in
                future.fail(with: error)
            }).send()
        }
    }
    
    /// Return a new future with the results of both futures.
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func join<U>(_ callback: @escaping (T) throws -> ResponseFuture<U>) -> ResponseFuture<(T, U)> {
        return ResponseFuture<(T, U)>(order: order + 1) { future in
            let secondWeight = Float(1)/Float(future.order)
            let firstWeight = 1 - secondWeight
            
            self.success({ response in
                let newFuture = try callback(response)
                
                newFuture.success({ newResponse in
                    future.succeed(with: (response, newResponse))
                }).error({ error in
                    future.fail(with: error)
                }).progress({ progress in
                    let newProgress = firstWeight + (progress * secondWeight)
                    future.update(progress: newProgress)
                }).send()
            }).error({ error in
                future.fail(with: error)
            }).progress({ progress in
                let newProgress = progress * firstWeight
                future.update(progress: newProgress)
            }).send()
        }
    }
    
    /// Return a new future with the results of the future retuned in the callback.
    ///
    /// - Parameter callback: The future that returns the results we want to return.
    /// - Returns: The
    public func replace<U>(_ callback: @escaping (T) throws -> ResponseFuture<U>) -> ResponseFuture<U> {
        return ResponseFuture<U>(order: order + 1) { future in
            let secondWeight = Float(1)/Float(future.order)
            let firstWeight = 1 - secondWeight
            
            self.success({ response in
                let newPromise = try callback(response)
                
                newPromise.success({ newResponse in
                    future.succeed(with: newResponse)
                }).progress({ progress in
                    let newProgress = firstWeight + (progress * secondWeight)
                    future.update(progress: newProgress)
                }).error({ error in
                    future.fail(with: error)
                }).send()
            }).error({ error in
                future.fail(with: error)
            }).progress({ progress in
                let newProgress = progress * firstWeight
                future.update(progress: newProgress)
            }).send()
        }
    }
    
    /// This method triggers the action method defined on this promise.
    public func start() {
        do {
            self.status = .started
            try action?(self)
            action = nil
        } catch {
            self.fail(with: error)
        }
    }
    
    /// This method triggers the action method defined on this promise.
    public func send() {
        start()
    }
}
