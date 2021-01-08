//
//  RequestError.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

/// An error object to cover any errors that are triggered by the `RequestSerializer` when attempting to create a `URLRequest`
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
