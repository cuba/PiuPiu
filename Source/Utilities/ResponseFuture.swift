//
//  Promise.swift
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
    
    private let action: ActionCallback
    private var successHandler: SuccessHandler?
    private var errorHandler: ErrorHandler?
    private var completionHandler: CompletionHandler?
    
    /// The status of the promise.
    private(set) public var status: Status
    
    /// Initialize the promise with an action that is triggered when calling the start() method.
    ///
    /// - Parameter action: The action that is performed. The action returns this promise when triggered.
    public init(action: @escaping ActionCallback) {
        self.action = action
        self.status = .created
    }
    
    /// Initialize the promise with an result that triggers the success callback as soon as `send` or `start` is called.
    ///
    /// - Parameter result: The result that is returned right away.
    public convenience init(result: T) {
        self.init() { future in
            future.succeed(with: result)
        }
    }
    
    /// Fulfills the given promise with the results of the given promise. Both promises have to be of the same type.
    ///
    /// - Parameter promise: The promise to be fulfilled.
    public func fulfill(_ promise: ResponseFuture<T>) {
        self.success({ result in
            promise.succeed(with: result)
        }).error({ error in
            promise.fail(with: error)
        }).send()
    }
    
    /// Fulfills the given promise with the results of the given promise. Both promises have to be of the same type.
    ///
    /// - Parameter promise: The promise to be fulfilled.
    public func fulfill(with promise: ResponseFuture<T>) {
        promise.success({ result in
            self.succeed(with: result)
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
    ///
    /// - Parameter callback: The callback that does the conversion.
    /// - Returns: The coverted promise
    public func then<U>(_ callback: @escaping (T) throws -> U) -> ResponseFuture<U> {
        return ResponseFuture<U>() { promise in
            self.success({ result in
                let transformed = try callback(result)
                promise.succeed(with: transformed)
            }).error({ error in
                promise.fail(with: error)
            }).send()
        }
    }
    
    /// Return a new future with the results of both futures.
    ///
    /// - Parameter callback: The callback that returns the nested future
    /// - Returns: A new future with the results of both futures
    public func join<U>(_ callback: @escaping (T) throws -> ResponseFuture<U>) -> ResponseFuture<(T, U)> {
        return ResponseFuture<(T, U)>() { future in
            self.success({ response in
                let newPromise = try callback(response)
                
                newPromise.success({ newResponse in
                    future.succeed(with: (response, newResponse))
                }).error({ error in
                    future.fail(with: error)
                }).send()
            }).error({ error in
                future.fail(with: error)
            }).send()
        }
    }
    
    /// Return a new future with the results of the future retuned in the callback.
    ///
    /// - Parameter callback: The future that returns the results we want to return.
    /// - Returns: The
    public func replace<U>(_ callback: @escaping (T) throws -> ResponseFuture<U>) -> ResponseFuture<U> {
        return ResponseFuture<U>() { future in
            self.success({ response in
                let newPromise = try callback(response)
                
                newPromise.success({ newResponse in
                    future.succeed(with: newResponse)
                }).error({ error in
                    future.fail(with: error)
                }).send()
            }).error({ error in
                future.fail(with: error)
            }).send()
        }
    }
    
    /// This method triggers the action method defined on this promise.
    ///
    /// - Returns: `self`
    @discardableResult
    public func start() -> ResponseFuture<T> {
        do {
            self.status = .started
            try action(self)
        } catch {
            self.fail(with: error)
        }
        
        return self
    }
    
    /// This method triggers the action method defined on this promise.
    ///
    /// - Returns: `self`
    @discardableResult
    public func send() -> ResponseFuture<T> {
        return start()
    }
}
