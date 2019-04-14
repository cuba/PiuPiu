//
//  Response+Extensions.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-04-12.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import PewPew
import ObjectMapper
import MapCodableKit

// MARK: - BaseMappable

extension ResponseInterface where T == Data? {
    
    /// Attempt to Decode the response data into an BaseMappable object.
    ///
    /// - Returns: The decoded object
    func decodeMappable<D: BaseMappable>(_ type: D.Type, context: MapContext? = nil) throws  -> D {
        let jsonString = try self.decodeString()
        let mapper = Mapper<D>(context: context)
        
        guard let result = mapper.map(JSONString: jsonString) else {
            throw SerializationError.failedToDecodeResponseData(cause: nil)
        }
        
        return result
    }
    
    /// Attempt to decode the response data into a BaseMappable array.
    ///
    /// - Returns: The decoded array
    func decodeMappable<D: BaseMappable>(_ type: [D].Type, context: MapContext? = nil) throws  -> [D] {
        let jsonString = try self.decodeString()
        let mapper = Mapper<D>(context: context)
        
        guard let result = mapper.mapArray(JSONString: jsonString) else {
            throw SerializationError.failedToDecodeResponseData(cause: nil)
        }
        
        return result
    }
}

// MARK: - MapDecodable

extension ResponseInterface where T == Data? {
    
    /// Attempt to deserialize the response data into a MapDecodable object.
    ///
    /// - Returns: The decoded object
    func decodeMapDecodable<D: MapDecodable>(_ type: D.Type) throws -> D {
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
    func decodeMapDecodable<D: MapDecodable>(_ type: [D].Type) throws  -> [D] {
        let data = try self.unwrapData()
        
        do {
            // Attempt to deserialize the object.
            return try D.parseArray(jsonData: data)
        } catch {
            // Wrap this error so that we're controlling the error type and return a safe message to the user.
            throw SerializationError.failedToDecodeResponseData(cause: error)
        }
    }
}
