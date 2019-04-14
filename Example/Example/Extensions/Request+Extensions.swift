//
//  Request+Extensions.swift
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

extension BasicRequest {
    /// Add JSON body to the request from a `BaseMappable` object.
    ///
    /// - Parameters:
    ///   - mappable: The `BaseMappable` object to serialize into JSON.
    ///   - context: The context of the mapping object
    ///   - shouldIncludeNilValues: Wether or not we should serialize nil values into the json object
    mutating func setJSONBody<T: BaseMappable>(mappable: T, context: MapContext? = nil, shouldIncludeNilValues: Bool = false) {
        let mapper = Mapper<T>(context: context, shouldIncludeNilValues: shouldIncludeNilValues)
        
        guard let jsonString = mapper.toJSONString(mappable) else {
            return
        }
        
        self.setJSONBody(string: jsonString)
    }
    
    /// Add JSON body to the request from a `BaseMappable` array.
    ///
    /// - Parameters:
    ///   - mappable: The `BaseMappable` array to serialize into JSON.
    ///   - context: The context of the mapping object
    ///   - shouldIncludeNilValues: Wether or not we should serialize nil values into the json object
    mutating func setJSONBody<T: BaseMappable>(mappable: [T], context: MapContext? = nil, shouldIncludeNilValues: Bool = false) {
        let mapper = Mapper<T>(context: context, shouldIncludeNilValues: shouldIncludeNilValues)
        
        guard let jsonString = mapper.toJSONString(mappable) else {
            return
        }
        
        self.setJSONBody(string: jsonString)
    }
}

// MARK: - MapEncodable

extension BasicRequest {
    
    /// Add body to the request from a `MapEncodable` object.
    ///
    /// - Parameters:
    ///   - mapEncodable: The `MapEncodable` object to serialize into JSON.
    ///   - options: Writing options for serializing the `MapEncodable` object.
    /// - Throws: Any serialization errors thrown by `MapCodableKit`.
    mutating public func setJSONBody<T: MapEncodable>(mapEncodable: T, options: JSONSerialization.WritingOptions = []) throws {
        ensureJSONContentType()
        self.httpBody = try mapEncodable.jsonData(options: options)
    }
}
