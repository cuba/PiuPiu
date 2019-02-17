//
//  Promise+Extensions.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2019-02-16.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import MapCodableKit

extension Promise where T == SuccessResponse<Data?> {
    
    /// Attempts to unwrap the resposne data.
    ///
    /// - Returns: A promose containing the unwrapped data
    open func unwrapData() -> Promise<SuccessResponse<Data>, E> {
        return then() { response in
            // Check if we have the data we need
            guard let unwrappedData = response.data else {
                throw SerializationError.unexpectedEmptyResponse
            }
            
            return (unwrappedData, response.httpResponse, response.urlRequest, response.statusCode)
        }
    }
    
    /// Attempts to deserialize the resposne data into a JSON string.
    ///
    /// - Returns: A promose containing the deserilized results
    open func deserializeJSONString() -> Promise<SuccessResponse<String>, E> {
        return unwrapData().then { response in
            // Attempt to deserialize the object.
            guard let jsonString = String(data: response.data, encoding: .utf8) else {
                throw SerializationError.failedToDecodeResponseData(cause: nil)
            }
            
            return (jsonString, response.httpResponse, response.urlRequest, response.statusCode)
        }
    }
    
    /// Attempts to deserialize the resposne data into a MapDecodable object.
    ///
    /// - Returns: A promose containing the deserilized results
    open func deserializeMapDecodable<D: MapDecodable>(to: D.Type) -> Promise<SuccessResponse<D>, E> {
        return unwrapData().then { response in
            do {
                // Attempt to deserialize the object.
                let object = try D(jsonData: response.data)
                return (object, response.httpResponse, response.urlRequest, response.statusCode)
            } catch {
                // Wrap this error so that we're controlling the error type and return a safe message to the user.
                throw SerializationError.failedToDecodeResponseData(cause: error)
            }
        }
    }
    
    /// Attempts to deserialize the resposne data into a MapDecodable array.
    ///
    /// - Returns: A promose containing the deserilized results
    open func deserializeMapDecodable<D: MapDecodable>(to: [D].Type) -> Promise<SuccessResponse<[D]>, E> {
        return unwrapData().then { response in
            do {
                // Attempt to deserialize the object.
                let object = try D.parseArray(jsonData: response.data)
                return (object, response.httpResponse, response.urlRequest, response.statusCode)
            } catch {
                // Wrap this error so that we're controlling the error type and return a safe message to the user.
                throw SerializationError.failedToDecodeResponseData(cause: error)
            }
        }
    }
    
    /// Attempts to deserialize the resposne data into a Decodable object.
    ///
    /// - Returns: A promose containing the deserilized results
    open func deserializeDecodable<D: Decodable>(to: D.Type) -> Promise<SuccessResponse<D>, E> {
        return unwrapData().then { response in
            do {
                // Attempt to deserialize the object.
                let object = try JSONDecoder().decode(D.self, from: response.data)
                return (object, response.httpResponse, response.urlRequest, response.statusCode)
            } catch {
                // Wrap this error so that we're controlling the error type and return a safe message to the user.
                throw SerializationError.failedToDecodeResponseData(cause: error)
            }
        }
    }
    
    /// Attempts to deserialize the resposne data into a MapDecodable object.
    ///
    /// - Returns: A promose containing the deserilized results
    open func deserialize<D: MapDecodable>(to type: D.Type) -> Promise<SuccessResponse<D>, E> {
        return deserializeMapDecodable(to: type)
    }
    
    /// Attempts to deserialize the resposne data into a MapDecodable array.
    ///
    /// - Returns: A promose containing the deserilized results
    open func deserialize<D: MapDecodable>(to type: [D].Type) -> Promise<SuccessResponse<[D]>, E> {
        return deserializeMapDecodable(to: type)
    }
    
    /// Attempts to deserialize the resposne data into a Decodable object.
    ///
    /// - Returns: A promose containing the deserilized results
    open func deserialize<D: Decodable>(to type: D.Type) -> Promise<SuccessResponse<D>, E> {
        return deserializeDecodable(to: type)
    }
}

extension Promise where E == ErrorResponse<Data?> {
    
    /// Attempts to unwrap the resposne data.
    ///
    /// - Returns: A promose containing the unwrapped data
    open func unwrapErrorData() -> Promise<T, ErrorResponse<Data>> {
        return thenFailure() { response in
            // Check if we have the data we need
            guard let unwrappedData = response.data else {
                throw SerializationError.unexpectedEmptyResponse
            }
            
            return (unwrappedData, response.httpResponse, response.urlRequest, response.statusCode, response.error)
        }
    }
    
    /// Attempts to deserialize the resposne data into a JSON string.
    ///
    /// - Returns: A promose containing the deserilized results
    open func deserializeJSONString() -> Promise<T, ErrorResponse<String>> {
        return unwrapErrorData().thenFailure { response in
            // Attempt to deserialize the object.
            guard let jsonString = String(data: response.data, encoding: .utf8) else {
                throw SerializationError.failedToDecodeResponseData(cause: nil)
            }
            
            return (jsonString, response.httpResponse, response.urlRequest, response.statusCode, response.error)
        }
    }
    
    /// Attempts to deserialize the resposne data into a MapDecodable object.
    ///
    /// - Returns: A promose containing the deserilized results
    open func deserializeError<D: MapDecodable>(to: D.Type) -> Promise<T, ErrorResponse<D>> {
        return unwrapErrorData().thenFailure { response in
            do {
                // Attempt to deserialize the object.
                let object = try D(jsonData: response.data)
                return (object, response.httpResponse, response.urlRequest, response.statusCode, response.error)
            } catch {
                // Wrap this error so that we're controlling the error type and return a safe message to the user.
                throw SerializationError.failedToDecodeResponseData(cause: error)
            }
        }
    }
    
    /// Attempts to deserialize the resposne data into a MapDecodable array.
    ///
    /// - Returns: A promose containing the deserilized results
    open func deserializeError<D: MapDecodable>(to: [D].Type) -> Promise<T, ErrorResponse<[D]>> {
        return unwrapErrorData().thenFailure { response in
            do {
                // Attempt to deserialize the object.
                let object = try D.parseArray(jsonData: response.data)
                return (object, response.httpResponse, response.urlRequest, response.statusCode, response.error)
            } catch {
                // Wrap this error so that we're controlling the error type and return a safe message to the user.
                throw SerializationError.failedToDecodeResponseData(cause: error)
            }
        }
    }
    
    /// Attempts to deserialize the resposne data into a Decodable object.
    ///
    /// - Returns: A promose containing the deserilized results
    open func deserializeError<D: Decodable>(to: D.Type) -> Promise<T, ErrorResponse<D>> {
        return unwrapErrorData().thenFailure { response in
            do {
                // Attempt to deserialize the object.
                let object = try JSONDecoder().decode(D.self, from: response.data)
                return (object, response.httpResponse, response.urlRequest, response.statusCode, response.error)
            } catch {
                // Wrap this error so that we're controlling the error type and return a safe message to the user.
                throw SerializationError.failedToDecodeResponseData(cause: error)
            }
        }
    }
}

extension Promise {
    
    /// Calls the start() method on the promise
    ///
    /// - Returns: This promise
    @discardableResult
    public func send() -> Promise<T, E> {
        return start()
    }
}
