//
//  BasicRequest.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2018-12-02.
//  Copyright © 2018 Jacob Sikorski. All rights reserved.
//
import Foundation

/// A basic implementation of the `Request` protocol.
public struct BasicRequest: Request {
    /// The http method to use for the request
    public var method: HTTPMethod
    
    /// The path that will be appended to the URL
    public var path: String
    
    /// The query items to incude in the url
    public var queryItems: [URLQueryItem]
    
    /// The headers that will be attached to the request
    public var headers: [String: String]
    
    /// The http body
    public var httpBody: Data?
    
    /// Initialize this JSON request.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use
    ///   - path: The path that will be appended to the baseURL on the `ServerProvider`.
    ///   - queryItems: Query items that will be added to the url.
    ///   - headers: Headers that will be added to the request.
    public init(method: HTTPMethod, path: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:]) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.headers = [:]
        
        for (key, value) in headers {
            self.headers[key] = value
        }
    }
    
    /// Attempt to construct a `URL` from the request.
    ///
    /// - Parameter request: The request that will be sent.
    /// - Returns: A url to which the request will be sent.
    /// - throws: Any errors when trying to create the url.
    public func url(withBaseURL baseURL: URL) throws -> URL {
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = queryItems
        urlComponents?.path = path
        
        if let url = urlComponents?.url {
            return url
        } else {
            throw URLError(.badURL)
        }
    }
    
    /// Attempt to convert the request to a URLRequest.
    ///
    /// - Parameter request: The request that will be converted
    /// - Returns: The created URLRequest
    /// - throws: A RequstError object
    public func urlRequest(withBaseURL baseURL: URL) throws -> URLRequest {
        let url = try self.url(withBaseURL: baseURL)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = httpBody
        
        for (key, value) in headers {
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }
        
        return urlRequest
    }
    
    /// Add JSON body to the request from an `Encodable` object using the `JSONEncoder`.
    ///
    /// - Parameters:
    ///   - encodable: The `Encodable` object to serialize into JSON using the `JSONEncoder`.
    ///   - encoder: The `JSONEncoder` to use on the encodable object.
    /// - throws: Any serialization errors thrown by the `JSONEncoder`.
    mutating public func setJSONBody<T: Encodable>(encodable: T, encoder: JSONEncoder = JSONEncoder()) throws {
        self.httpBody = try encoder.encode(encodable)
        ensureJSONContentType()
    }
    
    /// Add JSON body to the request from an `Encodable` object using the `JSONEncoder`.
    ///
    /// - Parameters:
    ///   - encodable: The `Encodable` object to serialize into JSON using the `JSONEncoder`.
    ///   - encoder: The `JSONEncoder` to use on the encodable object.
    /// - throws: Any serialization errors thrown by the `JSONEncoder`.
    mutating public func setJSONBody<T: Encodable>(_ encodable: T, encoder: JSONEncoder = JSONEncoder()) throws {
        try setJSONBody(encodable: encodable, encoder: encoder)
    }
    
    /// Add JSON body to the request from an `Encodable` object using the `DateEncodingStrategy`.
    ///
    /// - Parameters:
    ///   - encodable: The `Encodable` object to serialize into JSON using the `JSONEncoder`.
    ///   - dateEncodingStrategy: The `DateEncodingStrategy` to use on the encoder.
    /// - throws: Any serialization errors thrown by the `JSONEncoder`.
    mutating public func setJSONBody<T: Encodable>(encodable: T, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = dateEncodingStrategy
        try setJSONBody(encodable: encodable, encoder: encoder)
    }
    
    /// Add JSON body to the request from an `Encodable` object using the `DateEncodingStrategy`.
    ///
    /// - Parameters:
    ///   - encodable: The `Encodable` object to serialize into JSON using the `JSONEncoder`.
    ///   - dateEncodingStrategy: The `DateEncodingStrategy` to use on the encoder.
    /// - throws: Any serialization errors thrown by the `JSONEncoder`.
    mutating public func setJSONBody<T: Encodable>(_ encodable: T, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = dateEncodingStrategy
        try setJSONBody(encodable: encodable, encoder: encoder)
    }
    
    /// Add body to the request from a string.
    ///
    /// - Parameters:
    ///   - string: The string to add to the body.
    ///   - encoding: The encoding type to use when adding the string.
    mutating public func setHTTPBody(string: String, encoding: String.Encoding = .utf8) {
        self.httpBody = string.data(using: encoding)
    }
    
    /// Add JSON body to the request from a string. Adds the content type header.
    ///
    /// - Parameters:
    ///   - string: The string to add to the body.
    ///   - encoding: The encoding type to use when adding the string.
    mutating public func setJSONBody(string: String, encoding: String.Encoding = .utf8) {
        self.setHTTPBody(string: string, encoding: encoding)
        ensureJSONContentType()
    }
    
    
    /// Add JSON body to the request from a JSON Object.
    ///
    /// - Parameters:
    ///   - jsonObject: The JSON Object to encode into the request body using `JSONSerialization`.
    ///   - options: The writing options to use when encoding.
    /// - throws: Any errors thrown by `JSONSerialization`.
    mutating public func setHTTPBody(jsonObject: [String: Any?], options: JSONSerialization.WritingOptions = []) throws {
        self.httpBody = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
    }
    
    /// Add HTTP body to the request from a JSON Object.
    ///
    /// - Parameters:
    ///   - jsonObject: The JSON Object to encode into the request body using `JSONSerialization`. This does the same thing as the `setHTTPBody(jsonArray:options:)` method except that it also adds to `Content-Type` header.
    ///   - options: The writing options to use when encoding.
    /// - throws: Any errors thrown by `JSONSerialization`.
    mutating public func setJSONBody(jsonObject: [String: Any?], options: JSONSerialization.WritingOptions = []) throws {
        try setHTTPBody(jsonObject: jsonObject, options: options)
        ensureJSONContentType()
    }
    
    /// Add HTTP body to the request from a JSON Array.
    ///
    /// - Parameters:
    ///   - jsonArray: The JSON Object array to encode into the request body using `JSONSerialization`.
    ///   - options: The writing options to use when encoding.
    /// - throws: Any errors thrown by `JSONSerialization`.
    mutating public func setHTTPBody(jsonArray: [[String: Any?]], options: JSONSerialization.WritingOptions = []) throws {
        self.httpBody = try JSONSerialization.data(withJSONObject: jsonArray, options: options)
    }
    
    /// Add JSON body to the request from a JSON Array. This does the same thing as the `setHTTPBody(jsonArray:options:)` method except that it also adds to `Content-Type` header.
    ///
    /// - Parameters:
    ///   - jsonArray: The JSON Object array to encode into the request body using `JSONSerialization`.
    ///   - options: The writing options to use when encoding.
    /// - throws: Any errors thrown by `JSONSerialization`.
    mutating public func setJSONBody(jsonArray: [[String: Any?]], options: JSONSerialization.WritingOptions = []) throws {
        try setHTTPBody(jsonArray: jsonArray, options: options)
        ensureJSONContentType()
    }
    
    mutating public func ensureJSONContentType() {
        if !self.headers.keys.contains("Content-Type") {
            self.headers["Content-Type"] = "application/json"
        }
    }
}
