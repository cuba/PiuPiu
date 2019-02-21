//
//  Promise.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2019-02-15.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A Promise is a delayed action that is performed after doing the `start()`.
public class Promise<T, E> {
    public typealias ActionCallback = (Promise<T, E>) throws -> Void
    public typealias SuccessHandler = (T) throws -> Void
    public typealias FailureHandler = (E) throws -> Void
    public typealias ErrorHandler = (Error) -> Void
    public typealias CompletionHandler = () -> Void
    
    public enum Status {
        case created
        case started
        case failure
        case success
        case error
        
        var isComplete: Bool {
            switch self {
            case .created   : return false
            case .started   : return false
            case .failure   : return true
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
    
    /// Fulfills this promise with the results of another promise of the same type.
    /// The promise passed needs to be converted to the same type using the `then` and `thenFailure` methods.
    ///
    /// - Parameter promise: The promise that fullfils this one.
    public func fullfill(_ promise: Promise<T, E>) {
        self.success({ result in
            promise.succeed(with: result)
        }).failure({ result in
            promise.fail(with: result)
        }).error({ error in
            promise.catch(error)
        }).start()
    }
    
    /// Fullfill this promise with a successful result.
    ///
    /// - Parameter object: The succeeded object required by the promise success callback.
    public func succeed(with object: T) {
        do {
            try successHandler?(object)
            status = .success
            completionHandler?()
            return
        } catch {
            self.catch(error)
        }
    }
    
    /// Fullfill the promise with a failed result.
    ///
    /// - Parameter object: The failed object required by the promise error callback.
    public func fail(with object: E) {
        do {
            try failureHandler?(object)
            status = .failure
            completionHandler?()
            return
        } catch {
            self.catch(error)
        }
    }
    
    /// Fullfill the promise with a failed result.
    ///
    /// - Parameter object: The failed object required by the promise error callback.
    public func `catch`(_ error: Error) {
        errorHandler?(error)
        status = .error
        completionHandler?()
    }
    
    /// Attach a success handler to this promise. Should be called before the `start()` method in case the promise is fulfilled synchronously.
    ///
    /// - Parameter handler: The success handler that will be trigged after the `succeed()` method is called.
    /// - Returns: This promise for chaining.
    public func success(_ handler: @escaping SuccessHandler) -> Promise<T, E> {
        self.successHandler = handler
        return self
    }
    
    /// Attach a failure handler to this promise. Should be called before the `start()` method in case the promise is fulfilled synchronously.
    ///
    /// - Parameter handler: The error handler that will be triggered after the `fail()` method is called.
    /// - Returns: This promise for chaining.
    public func failure(_ handler: @escaping FailureHandler) -> Promise<T, E> {
        self.failureHandler = handler
        return self
    }
    
    /// Attach a error handler to this promise that handles . Should be called before the `start()` method in case the promise is fulfilled synchronously.
    ///
    /// - Parameter handler: The error handler that will be triggered if anything is thrown inside the success callback.
    /// - Returns: This promise for chaining.
    public func error(_ handler: @escaping (Error) -> Void) -> Promise<T, E> {
        self.errorHandler = handler
        return self
    }
    
    /// Attach a completion handler to this promise. Should be called before the `start()` method in case the promise is fulfilled synchronously.
    ///
    /// - Parameter handler: The completion handler that will be triggered after the `succeed()` or `fail()` methods are triggered.
    /// - Returns: This promise for chaining.
    public func completion(_ handler: @escaping CompletionHandler) -> Promise<T, E> {
        self.completionHandler = handler
        return self
    }
    
    /// This method triggers the action method defined on this promise.
    ///
    /// - Returns: `self`
    @discardableResult
    public func start() -> Promise<T, E> {
        do {
            self.status = .started
            try action(self)
        } catch {
            self.catch(error)
        }
        
        return self
    }
    
    /// Convert the success callback to another type.
    ///
    /// - Parameter callback: The callback that does the conversion.
    /// - Returns: The coverted promise
    public func then<U>(_ callback: @escaping (T) throws -> U) -> Promise<U, E> {
        return Promise<U, E>() { promise in
            self.success({ result in
                let transformed = try callback(result)
                promise.succeed(with: transformed)
            }).failure({ result in
                promise.fail(with: result)
            }).error({ error in
                promise.catch(error)
            }).start()
        }
    }
    
    /// Convert the error callback to another type.
    ///
    /// - Parameter callback: The callback that does the conversion.
    /// - Returns: The coverted promise
    public func thenFailure<U>(_ callback: @escaping (E) throws -> U) -> Promise<T, U> {
        return Promise<T, U>() { promise in
            self.success({ result in
                promise.succeed(with: result)
            }).failure({ result in
                let transformed = try callback(result)
                promise.fail(with: transformed)
            }).error({ error in
                promise.catch(error)
            }).start()
        }
    }
}
