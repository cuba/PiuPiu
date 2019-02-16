//
//  Promise.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2019-02-15.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public class Promise<T, E> {
    public typealias ActionCallback = (Promise<T, E>) -> Void
    public typealias SuccessHandler = (T) -> Void
    public typealias ErrorHandler = (E) -> Void
    public typealias CompletionHandler = () -> Void
    
    public enum Status {
        case created
        case pending
        case failed
        case success
        
        var isComplete: Bool {
            switch self {
            case .pending   : return false
            case .created   : return false
            case .failed    : return true
            case .success   : return true
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
    
    /// Fullfill this promise with a successful result.
    ///
    /// - Parameter object: The succeeded object required by the promise success callback.
    public func succeed(with object: T) {
        status = .success
        successHandler?(object)
        completionHandler?()
    }
    
    /// Fullfill the promise with a failed result.
    ///
    /// - Parameter object: The failed object required by the promise error callback.
    public func fail(with object: E) {
        status = .failed
        errorHandler?(object)
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
    
    /// Attach a error handler to this promise. Should be called before the `start()` method in case the promise is fulfilled synchronously.
    ///
    /// - Parameter handler: The error handler that will be triggered after the `fail()` method is called.
    /// - Returns: This promise for chaining.
    @discardableResult
    public func error(_ handler: @escaping ErrorHandler) -> Promise<T, E> {
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
        action(self)
        return self
    }
}
