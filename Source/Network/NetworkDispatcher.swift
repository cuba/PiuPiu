//
//  NetworkDispatcher.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation
import MapCodableKit

// Response types
public typealias SuccessResponse<T> = (data: T, httpResponse: HTTPURLResponse, urlRequest: URLRequest, statusCode: StatusCode)
public typealias ErrorResponse<T> = (data: T, httpResponse: HTTPURLResponse, urlRequest: URLRequest, statusCode: StatusCode, error: ResponseError)

public protocol NetworkDispatcherInterface {
    func make(_ request: Request) -> Promise<SuccessResponse<Data?>, ErrorResponse<Data?>>
}

open class NetworkDispatcher: NetworkDispatcherInterface {
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
                        promise.fail(with: (data, response, urlRequest, statusCode, responseError) )
                    }
                } else {
                    DispatchQueue.main.async {
                        promise.succeed(with: (data, response, urlRequest, statusCode))
                    }
                }
            }
            
            task.resume()
        }
    }
}

open class MockDispatcher: NetworkDispatcherInterface, ServerProvider {
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
                promise.fail(with: (data, httpResponse, urlRequest, statusCode, mockError))
            } else {
                promise.succeed(with: (data, httpResponse, urlRequest, statusCode))
            }
        }
    }
}
