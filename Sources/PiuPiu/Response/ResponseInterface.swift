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
    
    /// The data object that is attached to this response as specified by the user
    var data: T { get }
    
    /// The `URLRequest` that is returned on a successful response.
    /// **Note**: successful responses includes all responses incuding ones with `5xx` status codes
    var urlResponse: URLResponse { get }
    
    /// The original `URLRequest` that was used to create the request.
    var urlRequest: URLRequest { get }
}

public extension ResponseInterface where T == Data? {
    /// Attempts to cast the `URLRequest` to a `HTTPURLResponse` and returns a wrapping `HTTPResponse` object if succesful.
    /// - Returns: The `HTTPResponse` object which wraps the `HTTPURLResponse`
    /// - throws: `ResponseError.notHTTPResponse`
    func makeHTTPResponse() throws -> HTTPResponse<T> {
        // Ensure there is a http response
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw ResponseError.notHTTPResponse
        }
        
        return HTTPResponse(data: data, urlRequest: urlRequest, httpResponse: httpResponse)
    }
    
    /// Attempt to unwrap the response data.
    ///
    /// - Returns: The unwrapped object
    /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
    func unwrapData() throws -> Data {
        // Check if we have the data we need
        guard let unwrappedData = data else {
            throw ResponseError.unexpectedEmptyResponse
        }
        
        return unwrappedData
    }
    
    /// Attempt to deserialize the response data into a JSON string.
    ///
    /// - Parameter encoding: The string encoding type. The dafault is `.utf8`.
    /// - Returns: The decoded object
    /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
    /// - throws: `ResponseError.failedToDecodeDataToString` if the data cannot be transformed into a string
    func decodeString(encoding: String.Encoding = .utf8) throws -> String {
        let data = try unwrapData()
        
        // Attempt to deserialize the object.
        guard let string = String(data: data, encoding: encoding) else {
            throw ResponseError.failedToDecodeDataToString(encoding: encoding)
        }
        
        return string
    }
    
    /// Attempt to decode a JSON object (`Any`) from the response data.
    ///
    /// - Parameter options: Reading options. Default is set to `.mutableContainers`.
    /// - Returns: JSON object as `Any`
    /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
    /// - throws: An error if any value throws an error during decoding.
    func decodeJSONObject(options: JSONSerialization.ReadingOptions = .mutableContainers) throws -> Any {
        let data = try self.unwrapData()
        return try JSONSerialization.jsonObject(with: data, options: options)
    }
    
    /// Attempt to decode the response data into a `Decodable` object.
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type to decode
    ///   - dateDecodingStrategy: The default date encoding strategy to use.
    /// - Returns: The decoded object
    /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
    /// - throws: An error if any value throws an error during decoding.
    func decode<D: Decodable>(_ type: D.Type, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy) throws  -> D {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        return try decode(type, using: decoder)
    }
    
    /// Attempt to decode the response data into a `Decodable` object.
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
    /// - throws: An error if any value throws an error during decoding.
    func decode<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws  -> D {
        let data = try self.unwrapData()
        return try decoder.decode(type, from: data)
    }
    
    /// Attempt to decode the response data into a `Decodable` object.
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type to decode
    ///   - decoder: The decoder to use.
    /// - Returns: The decoded object
    /// - throws: An error if any value throws an error during decoding.
    func decodeIfPresent<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws  -> D? {
        guard let data = self.data else { return nil }
        return try decoder.decode(type, from: data)
    }
    
    /// A method to print the request and response in the console.
    /// **Warning** This should not be used in a production environment.
    func debug() {
        print("===========================================")
        print(makeRequestMarkdown())
        print("-------------------------------------------")
        print(makeResponseMarkdown())
        print("===========================================")
    }
    
    /// A method to print the request in the console.
    /// **Warning** This should not be used in a production environment. You should place this call behind a macro such as `DEBUG`
    func makeRequestMarkdown() -> String {
        var components: [String] = [
            "## REQUEST",
            "[\(urlRequest.httpMethod!)] \(urlRequest.url!)"
        ]
        
        if let headerFields = urlRequest.allHTTPHeaderFields {
            components.append("### Headers")
            
            for (key, value) in headerFields {
                components.append("* \(key): \(value)")
            }
        }
        
        if let body = urlRequest.httpBody {
            components.append("### Body")
            components.append("```json")
            
            if let json = String(data: body, encoding: .utf8) {
                components.append(json)
            } else {
                components.append(body.base64EncodedString())
            }
            
            components.append("```")
        }
        
        return components.joined(separator: "\n")
    }
    
    /// A method to print the response in the console.
    /// **Warning** This should not be used in a production environment. You should place this call behind a macro such as `DEBUG`
    func makeResponseMarkdown() -> String {
        var components: [String] = ["## RESPONSE"]
        
        if let httpResponse = self.urlResponse as? HTTPURLResponse {
            components.append("[\(urlRequest.httpMethod!)] (\(httpResponse.statusCode)) \(urlRequest.url!)")
            
            components.append("### Headers")
            for (key, value) in httpResponse.allHeaderFields {
                components.append("* \(key): \(value)")
            }
        } else {
            components.append("[\(urlRequest.httpMethod!)] \(urlRequest.url!)")
        }
        
        if data != nil {
            components.append("### Body")
            components.append("```json")
            do {
                let json = try decodeString(encoding: .utf8)
                components.append(json)
            } catch {
                components.append("\(error)")
            }
            components.append("```")
        }
        
        return components.joined(separator: "\n")
    }
}
