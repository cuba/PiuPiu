//
//  Response+Extensions.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-04-12.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import PiuPiu
import ObjectMapper
import MapCodableKit

// MARK: - BaseMappable

extension ResponseInterface where T == Data? {
    
    /// Attempt to Decode the response data into an BaseMappable object.
    ///
    /// - Parameters:
    ///   - type: The mappable type to decode
    ///   - context: The Base mappable object
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
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
    /// - Parameters:
    ///   - type: The array type to decode
    ///   - context: The Base mappable object
    /// - Returns: The decoded array
    /// - Throws: `SerializationError`
    func decodeMappable<D: BaseMappable>(_ type: [D].Type, context: MapContext? = nil) throws  -> [D] {
        let jsonString = try self.decodeString()
        let mapper = Mapper<D>(context: context)
        
        guard let result = mapper.mapArray(JSONString: jsonString) else {
            throw SerializationError.failedToDecodeResponseData(cause: nil)
        }
        
        return result
    }
    
    /// Attempt to decode the response data into a BaseMappable array.
    ///
    /// - Parameters:
    ///   - type: The dictionary type to decode
    ///   - context: The Base mappable object
    /// - Returns: The decoded array
    /// - Throws: `SerializationError`
    func decodeMappable<D: BaseMappable>(_ type: [String: D].Type, context: MapContext? = nil) throws  -> [String: D] {
        let jsonString = try self.decodeString()
        let mapper = Mapper<D>(context: context)
        
        guard let result = mapper.mapDictionary(JSONString: jsonString) else {
            throw SerializationError.failedToDecodeResponseData(cause: nil)
        }
        
        return result
    }
    
    /// Attempt to decode the response data into a BaseMappable array.
    ///
    /// - Parameters:
    ///   - type: The dictionary of arrays type to decode
    ///   - context: The Base mappable object
    /// - Returns: The decoded array
    /// - Throws: `SerializationError`
    func decodeMappable<D: BaseMappable>(_ type: [String: [D]].Type, context: MapContext? = nil) throws  -> [String: [D]] {
        let jsonObject = try self.decodeJSONObject()
        let mapper = Mapper<D>(context: context)
        
        guard let result = mapper.mapDictionaryOfArrays(JSONObject: jsonObject) else {
            throw SerializationError.failedToDecodeResponseData(cause: nil)
        }
        
        return result
    }
}

// MARK: - MapDecodable

extension ResponseInterface where T == Data? {
    
    /// Attempt to deserialize the response data into a MapDecodable object.
    ///
    /// - Parameters:
    ///   - type: The map decodable type to decode
    /// - Returns: The decoded object
    /// - Throws: `SerializationError`
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
    /// - Parameters:
    ///   - type: The map decodable array type to decode
    /// - Returns: The map decodable array
    /// - Throws: `SerializationError`
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
