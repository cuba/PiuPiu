//
//  Response+Extensions.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2019-02-21.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import MapCodableKit

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
