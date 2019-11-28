//
//  Transform.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public protocol EncodingTransform {
    associatedtype ValueSource
    associatedtype JSONDestination: Encodable
    
    func transform(value: Self.ValueSource) throws -> Self.JSONDestination
}

public protocol DecodingTransform {
    associatedtype JSONSource: Decodable
    associatedtype ValueDesitination
    
    func transform(json: Self.JSONSource) throws -> Self.ValueDesitination
}

public protocol Transform: EncodingTransform, DecodingTransform {}
