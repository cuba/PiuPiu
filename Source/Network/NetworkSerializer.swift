//
//  NetworkSerializer.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation
import MapCodableKit

// Old handlers
public typealias ErrorHandler = (Error) -> Void
public typealias CompletionHandler = () -> Void

// Response types
public typealias SuccessResponse<T> = (data: T, headers: [AnyHashable: Any])
public typealias ErrorResponse<T> = (error: BaseNetworkError, data: T, headers: [AnyHashable: Any]?)

open class NetworkSerializer {
    public var dispatcher: NetworkDispatcher
    
    /**
     Send a request while expecting a single `MapDecodable` object
     
     - parameter dispatcher: The Network dispatcher that will be used to send this request
     */
    public init(dispatcher: NetworkDispatcher) {
        self.dispatcher = dispatcher
    }
    
    open func send(_ request: Request) -> Promise<SuccessResponse<Data?>, ErrorResponse<Data?>> {
        return dispatcher.send(request)
    }
    
    /**
     Send a request while expecting a `MapDecodable` object
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send<T: MapDecodable>(_ request: Request, successHandler: @escaping (T, [AnyHashable: Any]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        dispatcher.send(request).deserializeMapDecodable().success({ response in
            successHandler(response.data, response.headers)
        }).failure({ response in
            errorHandler(response.error)
        }).error({ error in
            errorHandler(error)
        }).completion({
            completionHandler()
        }).start()
    }
    
    /**
     Send a request while expecting an array of `MapDecodable` objects
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send<T: MapDecodable>(_ request: Request, successHandler: @escaping ([T], [AnyHashable: Any]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        dispatcher.send(request).deserializeMapDecodableArray().success({ response in
            successHandler(response.data, response.headers)
        }).failure({ response in
            errorHandler(response.error)
        }).error({ error in
            errorHandler(error)
        }).completion({
            completionHandler()
        }).start()
    }
    
    /**
     Send a request while expecting a `Decodable` object
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func fetchDecodable<T: Decodable>(_ request: Request, successHandler: @escaping (T, [AnyHashable: Any]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        dispatcher.send(request).deserializeDecodable().success({ response in
            successHandler(response.data, response.headers)
        }).failure({ response in
            errorHandler(response.error)
        }).error({ error in
            errorHandler(error)
        }).completion({
            completionHandler()
        }).start()
    }
    
    /**
     Send a request while expecting an empty response
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send(_ request: Request, successHandler: @escaping ([AnyHashable: Any]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        dispatcher.send(request).success({ response in
            successHandler(response.headers)
        }).failure({ response in
            errorHandler(response.error)
        }).error({ error in
            errorHandler(error)
        }).completion({
            completionHandler()
        }).start()
    }
}
