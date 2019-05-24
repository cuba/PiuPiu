//
//  ResponseError.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum ResponseError: Error {
    case badRequest(cause: Error?)
    case unauthorized(cause: Error?)
    case forbidden(cause: Error?)
    case notFound(cause: Error?)
    case conflict(cause: Error?)
    case unprocessableEntity(cause: Error?)
    case internalServerError(cause: Error?)
    case serviceUnavailable(cause: Error?)
    case otherClientError(cause: Error?)
    case otherServerError(cause: Error?)
    case unknown(cause: Error?)
    
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
