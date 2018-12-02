//
//  NetworkSerializer.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation
import ObjectMapper

public typealias ErrorHandler = (Error) -> Void
public typealias CompletionHandler = () -> Void

open class NetworkSerializer {
    public var dispatcher: NetworkDispatcher
    
    /**
     Send a request while expecting a single `BaseMappable` object
     
     - parameter dispatcher: The Network dispatcher that will be used to send this request
     */
    public init(dispatcher: NetworkDispatcher) {
        self.dispatcher = dispatcher
    }
    
    /**
     Send a request while expecting a single `BaseMappable` object
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send<T: BaseMappable>(_ request: Request, successHandler: @escaping (T) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonObject: Any?, headers: [AnyHashable: Any]?) in
            let mapper = Mapper<T>()
            
            guard let object: T = mapper.map(JSONObject: jsonObject) else {
                let error = SerializationError.invalidObject(cause: nil)
                errorHandler(error)
                return
            }
            
            successHandler(object)
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    /**
     Send a request while expecting an array of `BaseMappable` objects
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send<T: BaseMappable>(_ request: Request, successHandler: @escaping ([T]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonObject: Any?, headers: [AnyHashable: Any]?) in
            let mapper = Mapper<T>()
            
            guard let object: [T] = mapper.mapArray(JSONObject: jsonObject) else {
                let error = SerializationError.invalidObject(cause: nil)
                errorHandler(error)
                return
            }
            
            successHandler(object)
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    /**
     Send a request while expecting a dictionary of `String` to `BaseMappable`
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send<T: BaseMappable>(_ request: Request, successHandler: @escaping ([String: T]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonObject: Any?, headers: [AnyHashable: Any]?) in
            let mapper = Mapper<T>()
            
            guard let object: [String: T] = mapper.mapDictionary(JSONObject: jsonObject) else {
                let error = SerializationError.invalidObject(cause: nil)
                errorHandler(error)
                return
            }
            
            successHandler(object)
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    /**
     Send a request while expecting a dictionary of `String` to `BaseMappable` `Array`
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send<T: BaseMappable>(_ request: Request, successHandler: @escaping ([String: [T]]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonObject: Any?, headers: [AnyHashable: Any]?) in
            let mapper = Mapper<T>()
            
            guard let object: [String: [T]] = mapper.mapDictionaryOfArrays(JSONObject: jsonObject) else {
                let error = SerializationError.invalidObject(cause: nil)
                errorHandler(error)
                return
            }
            
            successHandler(object)
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    /**
     Send a request while expecting a dictionary response
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send(_ request: Request, successHandler: @escaping ([String: String]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonObject: Any?, headers: [AnyHashable: Any]?) in
            guard let object = jsonObject as? [String: String] else {
                let error = SerializationError.invalidObject(cause: nil)
                errorHandler(error)
                return
            }
            
            successHandler(object)
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    /**
     Send a request while expecting an empty response
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send(_ request: Request, successHandler: @escaping () -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonObject: Any?) in
            successHandler()
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    /**
     Send a request while expecting a json response
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
    */
    open func send(_ request: Request, successHandler: @escaping (Any?, [AnyHashable: Any]?) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        dispatcher.send(request) { jsonObject, headers, error in
            if let error = error {
                errorHandler(error)
            } else {
                successHandler(jsonObject, headers)
            }
            
            completionHandler()
        }
    }
}
