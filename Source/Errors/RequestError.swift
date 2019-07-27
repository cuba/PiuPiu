//
//  RequestError.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-02-16.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//
import Foundation

public enum RequestError: Error {
    case missingURL
    case missingServerProvider
    
    public var errorKey: String {
        switch self {
        case .missingURL            : return "MissingURL"
        case .missingServerProvider : return "MissingServerProvider"
        }
    }
}
