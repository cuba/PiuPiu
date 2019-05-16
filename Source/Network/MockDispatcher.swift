//
//  MockDispatcher.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-03-31.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A mock dispatcher that does not actually make any network calls.
open class MockDispatcher: Dispatcher, ServerProvider {
    open var mockData: Data?
    open var mockStatusCode: StatusCode
    open var mockHeaders: [String: String]
    open var delay: TimeInterval = 0
    public var baseURL: URL?
    
    func response(from request: Request) throws -> Response<Data?> {
        let urlRequest = try self.urlRequest(from: request)
        let statusCode = self.mockStatusCode
        let headers = self.mockHeaders
        let data = self.mockData
        let url = urlRequest.url!
        let error = self.mockStatusCode.makeError(cause: nil)
        let httpResponse = HTTPURLResponse(url: url, statusCode: statusCode.rawValue, httpVersion: nil, headerFields: headers)!
        
        let response = Response(data: data, httpResponse: httpResponse, urlRequest: urlRequest, statusCode: statusCode, error: error)
        
        return response
    }
    
    
    /// Initialize this object with some mock data.
    ///
    /// - Parameters:
    ///   - baseUrl: The base url that is used to construct the url on the response
    ///   - mockStatusCode: The status code to return
    ///   - mockError: The error to return (if any)
    ///   - mockHeaders: The headers that will be returned
    public init(baseUrl: URL, mockStatusCode: StatusCode, mockHeaders: [String: String] = [:]) {
        self.baseURL = baseUrl
        self.mockStatusCode = mockStatusCode
        self.mockHeaders = mockHeaders
    }
    
    /// Encode the object as a fake JSON response
    ///
    /// - Parameter encodable: The object to encode into JSON
    /// - Throws: Throws if the object cannot be encoded
    public func setMockData<T: Encodable>(encodable: T) throws {
        self.mockData = try JSONEncoder().encode(encodable)
    }
    
    /// Encode the object as a JSON response
    ///
    /// - Parameters:
    ///   - jsonObject: The object to encode into JSON
    ///   - options: The encoding options
    /// - Throws: Throws if the object cannot be encoded.
    public func setMockData(jsonObject: [String: Any?], options: JSONSerialization.WritingOptions = []) throws {
        self.mockData = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
    }
    
    /// Encode the object as a fake JSON response
    ///
    /// - Parameters:
    ///   - jsonString: The string to encode
    ///   - encoding: The string encoding that will be used
    public func setMockData(jsonString: String, encoding: String.Encoding = .utf8) {
        self.mockData = jsonString.data(using: encoding)
    }
    
    /// Encode the object as a fake JSON response
    ///
    /// - Parameter encodable: The object to encode into JSON
    /// - Throws: Throws if the object cannot be encoded
    public func setMockData<T: Encodable>(_ encodable: T) throws {
        try setMockData(encodable: encodable)
    }
    
    /// Make a promise to send the request.
    ///
    /// - Parameter request: The request to send.
    /// - Returns: The promise that will send the request.
    public func future(from request: Request, on queue: DispatchQueue) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { promise in
            let response = try self.response(from: request)
            
            queue.asyncAfter(deadline: .now() + self.delay) {
                promise.succeed(with: response)
            }
        }
    }
}
