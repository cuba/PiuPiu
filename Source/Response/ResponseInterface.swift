//
//  ResponseInterface.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-15.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// The protocol wrapping the response object.
public protocol ResponseInterface {
    associatedtype T
    
    var data: T { get }
    var httpResponse: HTTPURLResponse { get }
    var urlRequest: URLRequest { get }
    var statusCode: StatusCode { get }
}

public extension ResponseInterface where T == Data? {
    /// Attempt to unwrap the response data.
    ///
    /// - Returns: The unwrapped object
    /// - Throws: `SerializationError`
    func unwrapData() throws -> Data {
        // Check if we have the data we need
        guard let unwrappedData = data else {
            throw SerializationError.unexpectedEmptyResponse
        }
        
        return unwrappedData
    }
    
    /// Attempt to deserialize the response data into a JSON string.
    ///
    /// - Parameter encoding: The string encoding type. The dafault is `.utf8`.
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
    func decodeString(encoding: String.Encoding = .utf8) throws -> String {
        let data = try unwrapData()
        
        // Attempt to deserialize the object.
        guard let string = String(data: data, encoding: encoding) else {
            throw SerializationError.failedToDecodeDataToString(encoding: encoding)
        }
        
        return string
    }
    
    /// Attempt to decode a JSON object (`Any`) from the response data.
    ///
    /// - Parameter options: Reading options. Default is set to `.mutableContainers`.
    /// - Returns: JSON object as `Any`
    /// - Throws: `SerializationError`
    func decodeJSONObject(options: JSONSerialization.ReadingOptions = .mutableContainers) throws -> Any {
        let data = try self.unwrapData()
        return try JSONSerialization.jsonObject(with: data, options: options)
    }
    
    /// Attempt to Decode the response data into a Decodable object.
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode
    ///   - dateDecodingStrategy: The default date encoding strategy to use. The default is `.rfc3339` (`yyyy-MM-dd'T'HH:mm:ssZZZZZ`)
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
    func decode<D: Decodable>(_ type: D.Type, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .rfc3339) throws  -> D {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        return try decode(type, using: decoder)
    }
    
    /// Attempt to Decode the response data into a Decodable object.
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
    func decode<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder) throws  -> D {
        let data = try self.unwrapData()
        return try decoder.decode(type, from: data)
    }
}

public extension ResponseInterface where Self.T == Data? {
    
    /// A method to print the request and response in the console.
    /// **Warning** This should not be used in a production environment.
    func debug() {
        print("===========================================")
        printRequest()
        print("-------------------------------------------")
        printResponse()
        print("===========================================")
    }
    
    /// A method to print the request in the console.
    /// **Warning** This should not be used in a production environment.
    func printRequest() {
        print("REQUEST [\(urlRequest.httpMethod!)] \(urlRequest.url!)")
        
        if let headersString = urlRequest.allHTTPHeaderFields?.map({ "    \($0): \($1)" }).joined(separator: "\n") {
            print("Headers:\n\(headersString)")
        }
        
        if let body = urlRequest.httpBody {
            if let json = String(data: body, encoding: .utf8) {
                print("Body: \(json)")
            } else {
                print("Body: [Not JSON]")
            }
        }
    }
    
    /// A method to print the response in the console.
    /// **Warning** This should not be used in a production environment.
    func printResponse() {
        print("RESPONSE [\(urlRequest.httpMethod!)] (\(statusCode.rawValue)) \(urlRequest.url!)")
        
        let headersString = httpResponse.allHeaderFields.map({ "    \($0): \($1)" }).joined(separator: "\n")
        print("Headers:\n\(headersString)")
        
        if data != nil {
            do {
                let json = try decodeString(encoding: .utf8)
                print("Body: \(json)")
            } catch {
                print("Body: \(error)")
            }
        }
    }
}
