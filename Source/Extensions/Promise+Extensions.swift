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
    
    open func deserializeData() -> Promise<SuccessResponse<Data>, E> {
        return then() { response in
            // Check if we have the data we need
            guard let unwrappedData = response.data else {
                throw SerializationError.unexpectedEmptyResponse
            }
            
            return (unwrappedData, response.httpResponse, response.urlRequest, response.statusCode)
        }
    }
    
    open func deserializeJSONString() -> Promise<SuccessResponse<String>, E> {
        return deserializeData().then { response in
            // Attempt to deserialize the object.
            guard let jsonString = String(data: response.data, encoding: .utf8) else {
                throw SerializationError.failedToDecodeResponseData(cause: nil)
            }
            
            return (jsonString, response.httpResponse, response.urlRequest, response.statusCode)
        }
    }
    
    open func deserializeMapDecodable<D: MapDecodable>() -> Promise<SuccessResponse<D>, E> {
        return deserializeData().then { response in
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
    
    open func deserializeMapDecodableArray<D: MapDecodable>() -> Promise<SuccessResponse<[D]>, E> {
        return deserializeData().then { response in
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
    
    open func deserializeDecodable<D: Decodable>() -> Promise<SuccessResponse<D>, E> {
        return deserializeData().then { response in
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
}
