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
        return Promise<SuccessResponse<Data>, E>() { promise in
            self.success({ response in
                // Check if we have the data we need
                guard let unwrappedData = response.data else {
                    throw SerializationError.unexpectedEmptyResponse
                }
                
                promise.succeed(with: (unwrappedData, response.headers))
            }).failure({ response in
                promise.fail(with: response)
            }).start()
        }
    }
    
    open func deserializeJSONString() -> Promise<SuccessResponse<String>, E> {
        return Promise<SuccessResponse<String>, E>() { promise in
            self.deserializeData().success({ response in
                do {
                    // Attempt to deserialize the object.
                    guard let jsonString = String(data: response.data, encoding: .utf8) else {
                        throw SerializationError.failedToDecodeResponseData(cause: nil)
                    }
                    
                    promise.succeed(with: (jsonString, response.headers))
                } catch {
                    // Wrap this error so that we're controlling the error type and return a safe message to the user.
                    throw SerializationError.failedToDecodeResponseData(cause: error)
                }
            }).failure({ response in
                promise.fail(with: response)
            }).start()
        }
    }
    
    open func deserializeMapDecodable<D: MapDecodable>() -> Promise<SuccessResponse<D>, E> {
        return Promise<SuccessResponse<D>, E>() { promise in
            self.deserializeData().success({ response in
                do {
                    // Attempt to deserialize the object.
                    let object = try D(jsonData: response.data)
                    promise.succeed(with: (object, response.headers))
                } catch {
                    // Wrap this error so that we're controlling the error type and return a safe message to the user.
                    throw SerializationError.failedToDecodeResponseData(cause: error)
                }
            }).failure({ response in
                promise.fail(with: response)
            }).start()
        }
    }
    
    open func deserializeMapDecodableArray<D: MapDecodable>() -> Promise<SuccessResponse<[D]>, E> {
        return Promise<SuccessResponse<[D]>, E>() { promise in
            self.deserializeData().success({ response in
                do {
                    // Attempt to deserialize the object.
                    let object = try D.parseArray(jsonData: response.data)
                    promise.succeed(with: (object, response.headers))
                } catch {
                    // Wrap this error so that we're controlling the error type and return a safe message to the user.
                    throw SerializationError.failedToDecodeResponseData(cause: error)
                }
            }).failure({ response in
                promise.fail(with: response)
            }).start()
        }
    }
    
    open func deserializeDecodable<D: Decodable>() -> Promise<SuccessResponse<D>, E> {
        return Promise<SuccessResponse<D>, E>() { promise in
            self.deserializeData().success({ response in
                do {
                    // Attempt to deserialize the object.
                    let object = try JSONDecoder().decode(D.self, from: response.data)
                    promise.succeed(with: (object, response.headers))
                } catch {
                    // Wrap this error so that we're controlling the error type and return a safe message to the user.
                    throw SerializationError.failedToDecodeResponseData(cause: error)
                }
            }).failure({ response in
                promise.fail(with: response)
            }).start()
        }
    }
}
