//
//  BasicRequest.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2018-12-02.
//  Copyright © 2018 Jacob Sikorski. All rights reserved.
//

import Foundation
import MapCodableKit

/// A convenience Request object for encoding JSON data.
public struct BasicRequest: Request {
    public var method: HTTPMethod
    public var path: String
    public var queryItems: [URLQueryItem]
    public var headers: [String: String]
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
    
    /// Add JSON body to the request from a `MapEncodable` object.
    ///
    /// - Parameters:
    ///   - mapEncodable: The `MapEncodable` object to serialize into JSON.
    ///   - options: Writing options for serializing the `MapEncodable` object.
    /// - Throws: Any serialization errors thrown by `MapCodableKit`.
    @available(*, deprecated, renamed: "setJSONBody(mapEncodable:options:)")
    mutating public func setHTTPBody<T: MapEncodable>(mapEncodable: T, options: JSONSerialization.WritingOptions = []) throws {
        try setJSONBody(mapEncodable: mapEncodable, options: options)
    }
    
    /// Add body to the request from a `MapEncodable` object.
    ///
    /// - Parameters:
    ///   - mapEncodable: The `MapEncodable` object to serialize into JSON.
    ///   - options: Writing options for serializing the `MapEncodable` object.
    /// - Throws: Any serialization errors thrown by `MapCodableKit`.
    mutating public func setJSONBody<T: MapEncodable>(mapEncodable: T, options: JSONSerialization.WritingOptions = []) throws {
        if !self.headers.keys.contains("Content-Type") {
            self.headers["Content-Type"] = "application/json"
        }
        
        self.httpBody = try mapEncodable.jsonData(options: options)
    }
    
    /// Add JSON body to the request from an `Encodable` object using the `JSONEncoder`.
    ///
    /// - Parameters:
    ///   - encodable: The `Encodable` object to serialize into JSON using the `JSONEncoder`.
    /// - Throws: Any serialization errors thrown by the `JSONEncoder`.
    @available(*, deprecated, renamed: "setJSONBody(encodable:dateEncodingStrategy:)")
    mutating public func setHTTPBody<T: Encodable>(encodable: T, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .rfc3339) throws {
        try setJSONBody(encodable: encodable, dateEncodingStrategy: dateEncodingStrategy)
    }
    
    /// Add JSON body to the request from an `Encodable` object using the `JSONEncoder`.
    ///
    /// - Parameters:
    ///   - encodable: The `Encodable` object to serialize into JSON using the `JSONEncoder`.
    /// - Throws: Any serialization errors thrown by the `JSONEncoder`.
    mutating public func setJSONBody<T: Encodable>(encodable: T, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .rfc3339) throws {
        let encoder = JSONEncoder()
        self.httpBody = try encoder.encode(encodable)
        ensureJSONContentType()
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
    /// - Throws: Any errors thrown by `JSONSerialization`.
    mutating public func setHTTPBody(jsonObject: [String: Any?], options: JSONSerialization.WritingOptions = []) throws {
        self.httpBody = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
        ensureJSONContentType()
    }
    
    /// Add JSON body to the request from a `MapEncodable` object.
    ///
    /// - Parameters:
    ///   - encodable: The `MapEncodable` object to serialize into JSON.
    ///   - options: Writing options for serializing the `MapEncodable` object.
    /// - Throws: Any serialization errors thrown by `MapCodableKit`.
    @available(*, deprecated, renamed: "setJSONBody(_:options:)")
    mutating public func setHTTPBody<T: MapEncodable>(_ encodable: T, options: JSONSerialization.WritingOptions = []) throws {
        try setJSONBody(mapEncodable: encodable, options: options)
    }
    
    /// Add JSON body to the request from a `MapEncodable` object.
    ///
    /// - Parameters:
    ///   - encodable: The `MapEncodable` object to serialize into JSON.
    ///   - options: Writing options for serializing the `MapEncodable` object.
    /// - Throws: Any serialization errors thrown by `MapCodableKit`.
    mutating public func setJSONBody<T: MapEncodable>(_ encodable: T, options: JSONSerialization.WritingOptions = []) throws {
        try setJSONBody(mapEncodable: encodable)
    }
    
    /// Add JSON body to the request from an `Encodable` object using the `JSONEncoder`.
    ///
    /// - Parameters:
    ///   - encodable: The `Encodable` object to serialize into JSON using the `JSONEncoder`.
    /// - Throws: Any serialization errors thrown by the `JSONEncoder`.
    @available(*, deprecated, renamed: "setJSONBody(_:dateEncodingStrategy:)")
    mutating public func setHTTPBody<T: Encodable>(_ encodable: T, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .rfc3339) throws {
        try setJSONBody(encodable: encodable, dateEncodingStrategy: dateEncodingStrategy)
    }
    
    /// Add JSON body to the request from an `Encodable` object using the `JSONEncoder`.
    ///
    /// - Parameters:
    ///   - encodable: The `Encodable` object to serialize into JSON using the `JSONEncoder`.
    /// - Throws: Any serialization errors thrown by the `JSONEncoder`.
    mutating public func setJSONBody<T: Encodable>(_ encodable: T, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .rfc3339) throws {
        try setJSONBody(encodable: encodable, dateEncodingStrategy: dateEncodingStrategy)
    }
    
    mutating private func ensureJSONContentType() {
        if !self.headers.keys.contains("Content-Type") {
            self.headers["Content-Type"] = "application/json"
        }
    }
}

public typealias JSONRequest = BasicRequest
