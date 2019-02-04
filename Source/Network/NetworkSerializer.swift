//
//  NetworkSerializer.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation
import MapCodableKit

public typealias ErrorHandler = (Error) -> Void
public typealias CompletionHandler = () -> Void

open class NetworkSerializer {
    public var dispatcher: NetworkDispatcher
    
    /**
     Send a request while expecting a single `MapDecodable` object
     
     - parameter dispatcher: The Network dispatcher that will be used to send this request
     */
    public init(dispatcher: NetworkDispatcher) {
        self.dispatcher = dispatcher
    }
    
    /**
     Send a request while expecting a single `MapDecodable` object
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send<T: MapDecodable>(_ request: Request, successHandler: @escaping (T, [AnyHashable: Any]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (data: Data?, headers: [AnyHashable: Any]) in
            guard let data = data else {
                let error = SerializationError.invalidObject(cause: nil)
                errorHandler(error)
                return
            }
            
            do {
                let object = try T(jsonData: data)
                successHandler(object, headers)
            } catch {
                errorHandler(error)
                return
            }
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    /**
     Send a request while expecting an array of `MapDecodable` objects
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send<T: MapDecodable>(_ request: Request, successHandler: @escaping ([T], [AnyHashable: Any]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonData: Data?, headers: [AnyHashable: Any]) in
            guard let jsonData = jsonData else {
                let error = SerializationError.invalidObject(cause: nil)
                errorHandler(error)
                return
            }
            
            do {
                let object = try T.parseArray(jsonData: jsonData)
                successHandler(object, headers)
            } catch {
                errorHandler(error)
                return
            }
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    /**
     Send a request while expecting a `Map` objects
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send(_ request: Request, successHandler: @escaping (Map, [AnyHashable: Any]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonData: Data?, headers: [AnyHashable: Any]) in
            guard let jsonData = jsonData else {
                let error = SerializationError.invalidObject(cause: nil)
                errorHandler(error)
                return
            }
            
            do {
                let object = try Map(jsonData: jsonData)
                successHandler(object, headers)
            } catch {
                errorHandler(error)
                return
            }
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    /**
     Send a request while expecting an array of `Map` objects
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send(_ request: Request, successHandler: @escaping ([Map], [AnyHashable: Any]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonData: Data?, headers: [AnyHashable: Any]) in
            guard let jsonData = jsonData else {
                let error = SerializationError.invalidObject(cause: nil)
                errorHandler(error)
                return
            }
            
            do {
                let object = try Map.parseArray(jsonData: jsonData)
                successHandler(object, headers)
            } catch {
                errorHandler(error)
                return
            }
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    /**
     Send a request while expecting an empty response
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send(_ request: Request, successHandler: @escaping ([AnyHashable: Any]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (data: Data?, headers: [AnyHashable: Any]) in
            successHandler(headers)
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    /**
     Send a request while expecting a json response
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
    */
    open func send(_ request: Request, successHandler: @escaping (Data?, [AnyHashable: Any]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        dispatcher.send(request) { data, headers, error in
            if let error = error {
                errorHandler(error)
            } else {
                successHandler(data, headers ?? [:])
            }
            
            completionHandler()
        }
    }
}
