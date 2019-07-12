//
//  ResponseInterface+Extensions.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-02-21.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

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
            throw SerializationError.failedToDecodeResponseData(cause: nil)
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
        
        do {
            return try JSONSerialization.jsonObject(with: data, options: options)
        } catch {
            throw SerializationError.failedToDecodeResponseData(cause: error)
        }
    }
    
    /// Attempt to Decode the response data into a Decodable object.
    ///
    /// - Parameters:
    ///   - type: The Decodable type to decode
    ///   - dateDecodingStrategy: The default date encoding strategy to use. The default is `.rfc3339` (`yyyy-MM-dd'T'HH:mm:ssZZZZZ`)
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
    func decode<D: Decodable>(_ type: D.Type, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .rfc3339) throws  -> D {
        let data = try self.unwrapData()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        
        do {
            // Attempt to deserialize the object.
            return try decoder.decode(D.self, from: data)
        } catch {
            // Wrap this error so that we're controlling the error type and return a safe message to the user.
            throw SerializationError.failedToDecodeResponseData(cause: error)
        }
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

public extension Response where T == Data? {
    /// Create a mock response object.
    ///
    /// - Parameters:
    ///   - urlRequest: The urlRequest to use on the response
    ///   - encodable: The object to encode into JSON
    ///   - statusCode: The statusCode to use on the response
    ///   - headers: The headers to use on the response
    /// - Returns: A response object with a Data? data type
    /// - Throws: Throws RequestError.missingUrl if a url cannot be taken from the urlRequest
    static func makeMockJSONResponse<T: Encodable>(with urlRequest: URLRequest, encodable: T, statusCode: StatusCode, headers: [String: String] = [:]) throws -> Response<Data?> {
        let data = try JSONEncoder().encode(encodable)
        return try makeMockResponse(with: urlRequest, data: data, statusCode: statusCode, headers: headers)
    }
    
    /// Create a mock response object.
    ///
    /// - Parameters:
    ///   - urlRequest: The urlRequest to use on the response
    ///   - jsonObject: The json object to encode
    ///   - options: The options that will be used for serialization
    ///   - statusCode: The statusCode to use on the response
    ///   - headers: The headers to use on the response
    /// - Returns: A response object with a Data? data type
    /// - Throws: Throws RequestError.missingUrl if a url cannot be taken from the urlRequest
    static func makeMockResponse(with urlRequest: URLRequest, jsonObject: [String: Any?], options: JSONSerialization.WritingOptions = [], statusCode: StatusCode, headers: [String: String] = [:]) throws -> Response<Data?> {
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
        return try makeMockResponse(with: urlRequest, data: data, statusCode: statusCode, headers: headers)
    }
    
    /// Create a mock response object.
    ///
    /// - Parameters:
    ///   - urlRequest: The urlRequest to use on the response
    ///   - jsonString: The string to encode
    ///   - encoding: The string encoding that will be used
    ///   - statusCode: The statusCode to use on the response
    ///   - headers: The headers to use on the response
    /// - Returns: A response object with a Data? data type
    /// - Throws: Throws RequestError.missingUrl if a url cannot be taken from the urlRequest
    static func makeMockResponse(with urlRequest: URLRequest, jsonString: String, encoding: String.Encoding = .utf8, statusCode: StatusCode, headers: [String: String] = [:]) throws -> Response<Data?> {
        let data = jsonString.data(using: encoding)
        return try makeMockResponse(with: urlRequest, data: data, statusCode: statusCode, headers: headers)
    }
    
    /// Create a mock response object.
    ///
    /// - Parameters:
    ///   - urlRequest: The urlRequest to use on the response
    ///   - data: The data to use on the response
    ///   - statusCode: The statusCode to use on the response
    ///   - headers: The headers to use on the response
    /// - Returns: A response object with a Data? data type
    /// - Throws: Throws RequestError.missingUrl if a url cannot be taken from the urlRequest
    static func makeMockResponse(with urlRequest: URLRequest, data: Data? = nil, statusCode: StatusCode, headers: [String: String] = [:]) throws -> Response<Data?> {
        guard let url = urlRequest.url else {
            throw RequestError.missingURL
        }
        
        let error = statusCode.error
        let httpResponse = HTTPURLResponse(url: url, statusCode: statusCode.rawValue, httpVersion: nil, headerFields: headers)!
        let response = Response(data: data, httpResponse: httpResponse, urlRequest: urlRequest, statusCode: statusCode, error: error)
        
        return response
    }
}
