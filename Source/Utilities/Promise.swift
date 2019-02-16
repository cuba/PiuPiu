//
//  Promise.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2019-02-15.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation


public class Promise<T, E> {
    public typealias ActionCallback = (Promise<T, E>) throws -> Void
    public typealias SuccessHandler = (T) throws -> Void
    public typealias FailureHandler = (E) -> Void
    public typealias ErrorHandler = (Error) -> Void
    public typealias CompletionHandler = () -> Void
    
    public enum Status {
        case created
        case pending
        case failure
        case success
        case error
        
        var isComplete: Bool {
            switch self {
            case .pending   : return false
            case .created   : return false
            case .failure    : return true
            case .success   : return true
            case .error     : return true
            }
        }
    }
    
    private let action: ActionCallback
    private var successHandler: SuccessHandler?
    private var failureHandler: FailureHandler?
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
    
    /// Fullfill this promise with a successful result.
    ///
    /// - Parameter object: The succeeded object required by the promise success callback.
    public func succeed(with object: T) {
        do {
            try successHandler?(object)
            status = .success
        } catch {
            errorHandler?(error)
            status = .error
        }
        
        completionHandler?()
    }
    
    /// Fullfill the promise with a failed result.
    ///
    /// - Parameter object: The failed object required by the promise error callback.
    public func fail(with object: E) {
        status = .failure
        failureHandler?(object)
        completionHandler?()
    }
    
    /// Attach a success handler to this promise. Should be called before the `start()` method in case the promise is fulfilled synchronously.
    ///
    /// - Parameter handler: The success handler that will be trigged after the `succeed()` method is called.
    /// - Returns: This promise for chaining.
    @discardableResult
    public func success(_ handler: @escaping SuccessHandler) -> Promise<T, E> {
        self.successHandler = handler
        return self
    }
    
    /// Attach a failure handler to this promise. Should be called before the `start()` method in case the promise is fulfilled synchronously.
    ///
    /// - Parameter handler: The error handler that will be triggered after the `fail()` method is called.
    /// - Returns: This promise for chaining.
    @discardableResult
    public func failure(_ handler: @escaping FailureHandler) -> Promise<T, E> {
        self.failureHandler = handler
        return self
    }
    
    /// Attach a error handler to this promise that handles . Should be called before the `start()` method in case the promise is fulfilled synchronously.
    ///
    /// - Parameter handler: The error handler that will be triggered if anything is thrown inside the success callback.
    /// - Returns: This promise for chaining.
    @discardableResult
    public func error(_ handler: @escaping (Error) -> Void) -> Promise<T, E> {
        self.errorHandler = handler
        return self
    }
    
    /// Attach a completion handler to this promise. Should be called before the `start()` method in case the promise is fulfilled synchronously.
    ///
    /// - Parameter handler: The completion handler that will be triggered after the `succeed()` or `fail()` methods are triggered.
    /// - Returns: This promise for chaining.
    @discardableResult
    public func completion(_ handler: @escaping CompletionHandler) -> Promise<T, E> {
        self.completionHandler = handler
        return self
    }
    
    /// This method triggers the action method defined on this promise.
    @discardableResult
    public func start() -> Promise<T, E> {
        do {
            try action(self)
        } catch {
            errorHandler?(error)
            status = .error
        }
        
        return self
    }
}
