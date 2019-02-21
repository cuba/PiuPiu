//
//  NetworkDispatcher.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation
import MapCodableKit

public protocol Response {
    associatedtype T
    
    var data: T { get }
    var httpResponse: HTTPURLResponse { get }
    var urlRequest: URLRequest { get }
    var statusCode: StatusCode { get }
}

public extension Response where T == Data? {
    
    /// Attempt to unwrap the response data.
    ///
    /// - Returns: The unwrapped object
    public func unwrapData() throws -> Data {
        // Check if we have the data we need
        guard let unwrappedData = data else {
            throw SerializationError.unexpectedEmptyResponse
        }
        
        return unwrappedData
    }
    
    /// Attempt to deserialize the response data into a JSON string.
    ///
    /// - Returns: The decoded object
    public func decodeString(encoding: String.Encoding = .utf8) throws -> String {
        let data = try unwrapData()
        
        // Attempt to deserialize the object.
        guard let string = String(data: data, encoding: encoding) else {
            throw SerializationError.failedToDecodeResponseData(cause: nil)
        }
        
        return string
    }
    
    /// Attempt to deserialize the response data into a MapDecodable object.
    ///
    /// - Returns: The decoded object
    public func decodeMapDecodable<D: MapDecodable>(_ type: D.Type) throws -> D {
        let data = try self.unwrapData()
        
        do {
            // Attempt to deserialize the object.
            return try D(jsonData: data)
        } catch {
            // Wrap this error so that we're controlling the error type and return a safe message to the user.
            throw SerializationError.failedToDecodeResponseData(cause: error)
        }
    }
    
    /// Attempt to decode the response data into a MapDecodable array.
    ///
    /// - Returns: The decoded array
    public func decodeMapDecodable<D: MapDecodable>(_ type: [D].Type) throws  -> [D] {
        let data = try self.unwrapData()
        
        do {
            // Attempt to deserialize the object.
            return try D.parseArray(jsonData: data)
        } catch {
            // Wrap this error so that we're controlling the error type and return a safe message to the user.
            throw SerializationError.failedToDecodeResponseData(cause: error)
        }
    }
    
    /// Attempt to Decode the response data into a Decodable object.
    ///
    /// - Returns: The decoded object
    public func decode<D: Decodable>(_ type: D.Type) throws  -> D {
        let data = try self.unwrapData()
        
        do {
            // Attempt to deserialize the object.
            return try JSONDecoder().decode(D.self, from: data)
        } catch {
            // Wrap this error so that we're controlling the error type and return a safe message to the user.
            throw SerializationError.failedToDecodeResponseData(cause: error)
        }
    }
}

// Response types
public struct SuccessResponse<T>: Response {
    public let data: T
    public let httpResponse: HTTPURLResponse
    public let urlRequest: URLRequest
    public let statusCode: StatusCode
    
    public init(data: T, httpResponse: HTTPURLResponse, urlRequest: URLRequest, statusCode: StatusCode) {
        self.data = data
        self.httpResponse = httpResponse
        self.urlRequest = urlRequest
        self.statusCode = statusCode
    }
    
    public init<U: Response>(data: T, response: U) {
        self.data = data
        self.httpResponse = response.httpResponse
        self.urlRequest = response.urlRequest
        self.statusCode = response.statusCode
    }
}

public struct ErrorResponse<T>: Response {
    public let data: T
    public let httpResponse: HTTPURLResponse
    public let urlRequest: URLRequest
    public let statusCode: StatusCode
    public let error: ResponseError
    
    public init(data: T, httpResponse: HTTPURLResponse, urlRequest: URLRequest, statusCode: StatusCode, error: ResponseError) {
        self.data = data
        self.httpResponse = httpResponse
        self.urlRequest = urlRequest
        self.statusCode = statusCode
        self.error = error
    }
    
    init<U: Response>(data: T, error: ResponseError, response: U) {
        self.data = data
        self.error = error
        self.httpResponse = response.httpResponse
        self.urlRequest = response.urlRequest
        self.statusCode = response.statusCode
    }
}

public protocol Dispatcher {
    func make(_ request: Request) -> Promise<SuccessResponse<Data?>, ErrorResponse<Data?>>
}

public extension Dispatcher {
    public func make(from callback: @escaping () throws -> Request) -> Promise<SuccessResponse<Data?>, ErrorResponse<Data?>> {
        return Promise<SuccessResponse<Data?>, ErrorResponse<Data?>>() { promise in
            let request = try callback()
            let requestPromise = self.make(request)
            requestPromise.fullfill(promise)
        }
    }
}


/// The object that will be making the API call.
open class NetworkDispatcher: Dispatcher {
    public weak var serverProvider: ServerProvider?
    
    public init(serverProvider: ServerProvider) {
        self.serverProvider = serverProvider
    }
    
    open func make(_ request: Request) -> Promise<SuccessResponse<Data?>, ErrorResponse<Data?>> {
        return Promise<SuccessResponse<Data?>, ErrorResponse<Data?>>() { promise in
            guard let serverProvider = self.serverProvider else {
                throw RequestError.missingServerProvider
            }
            
            let urlRequest = try serverProvider.urlRequest(from: request)
            
            let task = URLSession.shared.dataTask(with: urlRequest) { (data: Data?, urlResponse: URLResponse?, error: Error?) in
                // Ensure there is a status code (ex: 200)
                guard let response = urlResponse as? HTTPURLResponse else {
                    let error = ResponseError.unknown(cause: error)
                    DispatchQueue.main.async {
                        promise.catch(error)
                    }
                    return
                }
                
                let statusCode = StatusCode(rawValue: response.statusCode)
                
                // Get the status code
                if let responseError = statusCode.makeError(cause: error) {
                    DispatchQueue.main.async {
                        let errorResponse = ErrorResponse(data: data, httpResponse: response, urlRequest: urlRequest, statusCode: statusCode, error: responseError)
                        promise.fail(with: errorResponse)
                    }
                } else {
                    DispatchQueue.main.async {
                        let successResponse = SuccessResponse(data: data, httpResponse: response, urlRequest: urlRequest, statusCode: statusCode)
                        promise.succeed(with: successResponse)
                    }
                }
            }
            
            task.resume()
        }
    }
}

/// A mock dispatcher that does not actually make any network calls.
open class MockDispatcher: Dispatcher, ServerProvider {
    open var mockData: Data?
    open var mockStatusCode: StatusCode
    open var mockError: ResponseError?
    open var mockHeaders: [String: String]
    public var baseURL: URL
    
    public init(baseUrl: URL, mockStatusCode: StatusCode, mockError: ResponseError? = nil, mockHeaders: [String: String] = [:]) {
        self.baseURL = baseUrl
        self.mockStatusCode = mockStatusCode
        self.mockError = mockError
        self.mockHeaders = mockHeaders
    }
    
    func setMockData<T: MapEncodable>(mapEncodable: T, options: JSONSerialization.WritingOptions = []) throws {
        self.mockData = try mapEncodable.jsonData(options: options)
    }
    
    func setMockData<T: Encodable>(encodable: T) throws {
        self.mockData = try JSONEncoder().encode(encodable)
    }
    
    func setMockData(jsonString: String, encoding: String.Encoding = .utf8) {
        self.mockData = jsonString.data(using: encoding)
    }
    
    func setMockData(jsonObject: [String: Any?], options: JSONSerialization.WritingOptions = []) throws {
        self.mockData = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
    }
    
    // Convenience method.
    func setMockData<T: MapEncodable>(_ encodable: T) throws {
        try setMockData(mapEncodable: encodable)
    }
    
    func setMockData<T: Encodable>(_ encodable: T) throws {
        try setMockData(encodable: encodable)
    }
    
    public func make(_ request: Request) -> Promise<SuccessResponse<Data?>, ErrorResponse<Data?>> {
        return Promise<SuccessResponse<Data?>, ErrorResponse<Data?>>() { promise in
            let urlRequest = try self.urlRequest(from: request)
            let statusCode = self.mockStatusCode
            let headers = self.mockHeaders
            let data = self.mockData
            let url = urlRequest.url!
            let httpResponse = HTTPURLResponse(url: url, statusCode: statusCode.rawValue, httpVersion: nil, headerFields: headers)!
            
            if let mockError = self.mockError {
                let errorResponse = ErrorResponse(data: data, httpResponse: httpResponse, urlRequest: urlRequest, statusCode: statusCode, error: mockError)
                promise.fail(with: errorResponse)
            } else {
                let successResponse = SuccessResponse(data: data, httpResponse: httpResponse, urlRequest: urlRequest, statusCode: statusCode)
                promise.succeed(with: successResponse)
            }
        }
    }
}
