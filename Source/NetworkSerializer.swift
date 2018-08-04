//
//  NetworkSerializer.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation
import ObjectMapper

open class NetworkSerializer {
    public var dispatcher: NetworkDispatcher
    
    public init(dispatcher: NetworkDispatcher) {
        self.dispatcher = dispatcher
    }
    
    open func send<T: BaseMappable>(_ request: Request, successHandler: @escaping (T) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonObject: Any?) in
            let mapper = Mapper<T>()
            
            guard let object: T = mapper.map(JSONObject: jsonObject) else {
                let error = SerializationError.invalidObject(cause: nil)
                errorHandler(error)
                return
            }
            
            successHandler(object)
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    open func send<T: BaseMappable>(_ request: Request, successHandler: @escaping ([T]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonObject: Any?) in
            let mapper = Mapper<T>()
            
            guard let object: [T] = mapper.mapArray(JSONObject: jsonObject) else {
                let error = SerializationError.invalidObject(cause: nil)
                errorHandler(error)
                return
            }
            
            successHandler(object)
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    open func send<T: BaseMappable>(_ request: Request, successHandler: @escaping ([String: T]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonObject: Any?) in
            let mapper = Mapper<T>()
            
            guard let object: [String: T] = mapper.mapDictionary(JSONObject: jsonObject) else {
                let error = SerializationError.invalidObject(cause: nil)
                errorHandler(error)
                return
            }
            
            successHandler(object)
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    open func send<T: BaseMappable>(_ request: Request, successHandler: @escaping ([String: [T]]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonObject: Any?) in
            let mapper = Mapper<T>()
            
            guard let object: [String: [T]] = mapper.mapDictionaryOfArrays(JSONObject: jsonObject) else {
                let error = SerializationError.invalidObject(cause: nil)
                errorHandler(error)
                return
            }
            
            successHandler(object)
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    open func send(_ request: Request, successHandler: @escaping ([String: String]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonObject: Any?) in
            guard let object = jsonObject as? [String: String] else {
                let error = SerializationError.invalidObject(cause: nil)
                errorHandler(error)
                return
            }
            
            successHandler(object)
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    open func send(_ request: Request, successHandler: @escaping () -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        self.send(request, successHandler: { (jsonObject: Any?) in
            successHandler()
        }, errorHandler: errorHandler, completionHandler: completionHandler)
    }
    
    open func send(_ request: Request, successHandler: @escaping (Any?) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        
        dispatcher.send(request, responseHandler: { jsonObject, error in
            if let error = error {
                errorHandler(error)
            } else {
                successHandler(jsonObject)
            }
        }, completionHandler: completionHandler)
    }
}
