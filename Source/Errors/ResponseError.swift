//
//  ResponseError.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum ResponseError: Error {
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case conflict
    case unprocessableEntity
    case internalServerError
    case serviceUnavailable
    case otherClientError
    case otherServerError
    case unknown
    
    public var errorKey: String {
        switch self {
        case .badRequest            : return "BadRequest"
        case .unauthorized          : return "Unauthorized"
        case .forbidden             : return "Forbidden"
        case .notFound              : return "NotFound"
        case .conflict              : return "Conflict"
        case .unprocessableEntity   : return "UnprocessableEntity"
        case .internalServerError   : return "InternalServerError"
        case .serviceUnavailable    : return "ServiceUnavailable"
        case .otherClientError      : return "OtherClientError"
        case .otherServerError      : return "OtherClientError"
        case .unknown               : return "Unknown"
        }
    }
}
