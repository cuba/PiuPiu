//
//  RequestError.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-02-16.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum RequestError: Error {
    case invalidURL(cause: Error)
    case missingServerProvider
    case missingURL
    
    public var errorKey: String {
        switch self {
        case .invalidURL            : return "InvalidURL"
        case .missingServerProvider : return "MissingServerProvider"
        case .missingURL            : return "MissingURL"
        }
    }
}
