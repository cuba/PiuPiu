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
public typealias ErrorResponse<T> = (error: Error, data: T, headers: [AnyHashable: Any]?)
public typealias EmptyResponse = [AnyHashable: Any]

open class NetworkSerializer {
    public var dispatcher: NetworkDispatcher
    
    /**
     Send a request while expecting a single `MapDecodable` object
     
     - parameter dispatcher: The Network dispatcher that will be used to send this request
     */
    public init(dispatcher: NetworkDispatcher) {
        self.dispatcher = dispatcher
    }
    
    open func data(from request: Request) -> Promise<SuccessResponse<Data>, ErrorResponse<Data?>> {
        return Promise<SuccessResponse<Data>, ErrorResponse>(action: { [weak self] promise in
            self?.dispatcher.response(from: request).success({ response in
                // Check if we have the data we need
                guard let unwrappedData = response.data else {
                    let error = SerializationError.emptyResponse
                    promise.fail(with: (error, response.data, response.headers))
                    return
                }
                
                // We have a response object. Let's return it.
                promise.succeed(with: (unwrappedData, response.headers))
            }).error({ response in
                promise.fail(with: response)
            }).start()
        })
    }
    
    open func decode<T: MapDecodable>(_ type: T.Type, from request: Request) -> Promise<SuccessResponse<T>, ErrorResponse<Data?>> {
        return Promise<SuccessResponse<T>, ErrorResponse>() { [weak self] promise in
            // Nested promise that returns the data
            self?.data(from: request).success({ response in
                do {
                    // Attempt to serialize the object into the specified type
                    let object = try T(jsonData: response.data)
                    promise.succeed(with: (object, response.headers))
                } catch {
                    promise.fail(with: (error, response.data, response.headers))
                }
            }).error({ response in
                // TODO: Parse the error body
                promise.fail(with: response)
            }).start()
        }
    }
    
    open func decode<T: MapDecodable>(_ type: [T].Type, from request: Request) -> Promise<SuccessResponse<[T]>, ErrorResponse<Data?>> {
        return Promise<SuccessResponse<[T]>, ErrorResponse>() { [weak self] promise in
            // Nested promise that returns the data
            self?.data(from: request).success({ response in
                do {
                    // Attempt to serialize the object into the specified type
                    let object = try T.parseArray(jsonData: response.data)
                    promise.succeed(with: (object, response.headers))
                } catch {
                    promise.fail(with: (error, response.data, response.headers))
                }
            }).error({ response in
                // TODO: Parse the error body
                promise.fail(with: response)
            }).start()
        }
    }
    
    open func decode<T: Decodable>(_ type: T.Type, from request: Request) -> Promise<SuccessResponse<T>, ErrorResponse<Data?>> {
        return Promise<SuccessResponse<T>, ErrorResponse>() { [weak self] promise in
            // Nested promise that returns the data
            self?.data(from: request).success({ response in
                do {
                    // Attempt to serialize the object into the specified type
                    let object = try JSONDecoder().decode(T.self, from: response.data)
                    promise.succeed(with: (object, response.headers))
                } catch {
                    promise.fail(with: (error, response.data, response.headers))
                }
            }).error({ response in
                // TODO: Parse the error body
                promise.fail(with: response)
            }).start()
        }
    }
    
    open func emptyResponse(from request: Request) -> Promise<EmptyResponse, ErrorResponse<Data?>> {
        return Promise<EmptyResponse, ErrorResponse>() { [weak self] promise in
            self?.dispatcher.response(from: request).success({ response in
                promise.succeed(with: response.headers)
            }).error({ response in
                promise.fail(with: response)
            }).start()
        }
    }
    
    /**
     Send a request while expecting a `MapDecodable` object
     
     - parameter request: The request object containing all the request data
     - parameter successHandler: The callback that will be triggered on a secessful response
     - parameter errorHandler: The callback that will be triggered on a error response or invalid request
     - parameter completionHandler: The callback that will be triggered after either successHandler or errorHandler is triggered
     */
    open func send<T: MapDecodable>(_ request: Request, successHandler: @escaping (T, [AnyHashable: Any]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        decode(T.self, from: request).success({ response in
            successHandler(response.data, response.headers)
        }).error({ response in
            errorHandler(response.error)
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
        decode([T].self, from: request).success({ response in
            successHandler(response.data, response.headers)
        }).error({ response in
            errorHandler(response.error)
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
    open func send<T: Decodable>(_ request: Request, successHandler: @escaping (T, [AnyHashable: Any]) -> Void, errorHandler: @escaping ErrorHandler, completionHandler: @escaping CompletionHandler) {
        decode(T.self, from: request).success({ response in
            successHandler(response.data, response.headers)
        }).error({ response in
            errorHandler(response.error)
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
        emptyResponse(from: request).success({ headers in
            successHandler(headers)
        }).error({ response in
            errorHandler(response.error)
        }).completion({
            completionHandler()
        }).start()
    }
}
