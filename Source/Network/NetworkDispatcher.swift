//
//  NetworkDispatcher.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation
import MapCodableKit

public typealias ResponsePromise<T, E> = Promise<SuccessResponse<T>, ErrorResponse<E>>

/// The object that will be making the API call.
public protocol Dispatcher {
    
    /// Make a promise to send the network call.
    ///
    /// - Parameter callback: A callback that constructs the Request object.
    /// - Returns: A promise to make the network call.
    func make(_ request: Request) -> ResponsePromise<Data?, Data?>
}

public extension Dispatcher {
    
    /// Make a promise to send the network call.
    ///
    /// - Parameter callback: A callback that constructs the Request object.
    /// - Returns: A promise to make the network call.
    @available(*, deprecated, renamed: "makeRequest(from:)")
    public func make(from callback: @escaping () throws -> Request) -> ResponsePromise<Data?, Data?> {
        return makeRequest(from: callback)
    }
    
    /// Make a promise to send the network call.
    ///
    /// - Parameter callback: A callback that constructs the Request object.
    /// - Returns: A promise to make the network call.
    public func makeRequest(from callback: @escaping () throws -> Request) -> ResponsePromise<Data?, Data?> {
        return Promise<SuccessResponse<Data?>, ErrorResponse<Data?>>() { promise in
            let request = try callback()
            let requestPromise = self.make(request)
            requestPromise.fullfill(promise)
        }
    }
}


/// The class that will be making the API call.
open class NetworkDispatcher: Dispatcher {
    public weak var serverProvider: ServerProvider?
    
    /// Initialize this `Dispatcher` with a `ServerProvider`.
    ///
    /// - Parameter serverProvider: The server provider that will give the dispatcher the `baseURL`.
    public init(serverProvider: ServerProvider) {
        self.serverProvider = serverProvider
    }
    
    /// Make a promise to send the request.
    ///
    /// - Parameter request: The request to send.
    /// - Returns: The promise that will send the request.
    open func make(_ request: Request) -> ResponsePromise<Data?, Data?> {
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
