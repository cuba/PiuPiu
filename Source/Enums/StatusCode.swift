//
//  StatusCode.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2018-12-02.
//  Copyright © 2018 Jacob Sikorski. All rights reserved.
//

import Foundation

/// The status code returned by the server.
///
/// - ok: 200
/// - created: 201
/// - accepted: 202
/// - noContent: 204
/// - resetContent: 205
/// - partialContent: 206
/// - multiStatus: 207
/// - alreadyReported: 208
/// - imUsed: 226
/// - badRequest: 400
/// - unauthorized: 401
/// - paymentRequired: 402
/// - forbidden: 403
/// - notFound: 404
/// - methodNotAllowed: 405
/// - notAcceptable: 406
/// - unprocessableEntity: 422
/// - conflict: 409
/// - gone: 410
/// - lengthRequired: 411
/// - unsupportedMediaType: 415
/// - internalServerError: 500
/// - notImplemented: 501
/// - badGateway: 502
/// - serviceUnavailable: 503
/// - gatewayTimeout: 504
/// - httpVersionNotSupported: 505
/// - other: Any status codes not covered by this enum.
public enum StatusCode: Equatable {
   
    static let predefined: [StatusCode] = [
        .ok, .created, .accepted, .noContent, .resetContent, .partialContent, .multiStatus, .alreadyReported, .imUsed,
        .badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound, .methodNotAllowed, .notAcceptable, .unprocessableEntity, .conflict, .gone, .lengthRequired, .unsupportedMediaType,
        .internalServerError, .notImplemented, .badGateway, .serviceUnavailable, .gatewayTimeout, .httpVersionNotSupported
    ]
    
    // MARK: - 2xx
    
    /// 200
    case ok
    /// 201
    case created
    /// 202
    case accepted
    /// 204
    case noContent
    /// 205
    case resetContent
    /// 206
    case partialContent
    /// 207
    case multiStatus
    /// 208
    case alreadyReported
    /// 226
    case imUsed
    
    // MARK: - 4xx
    
    /// 400
    case badRequest
    /// 401
    case unauthorized
    /// 402
    case paymentRequired
    /// 403
    case forbidden
    /// 404
    case notFound
    /// 405
    case methodNotAllowed
    /// 406
    case notAcceptable
    /// 409
    case conflict
    /// 410
    case gone
    /// 411
    case lengthRequired
    /// 415
    case unsupportedMediaType
    /// 422
    case unprocessableEntity
    
    // MARK: - 5xx
    
    /// 500
    case internalServerError
    /// 501
    case notImplemented
    /// 502
    case badGateway
    /// 503
    case serviceUnavailable
    /// 504
    case gatewayTimeout
    /// 505
    case httpVersionNotSupported
    
    /// Any status code that does not fit in the predifined ones
    case other(Int)
    
    public var rawValue: Int {
        switch self {
        case .ok                        : return 200
        case .created                   : return 201
        case .accepted                  : return 202
        case .noContent                 : return 204
        case .resetContent              : return 205
        case .partialContent            : return 206
        case .multiStatus               : return 207
        case .alreadyReported           : return 208
        case .imUsed                    : return 226
        case .badRequest                : return 400
        case .unauthorized              : return 401
        case .paymentRequired           : return 402
        case .forbidden                 : return 403
        case .notFound                  : return 404
        case .methodNotAllowed          : return 405
        case .notAcceptable             : return 406
        case .conflict                  : return 409
        case .gone                      : return 410
        case .lengthRequired            : return 411
        case .unsupportedMediaType      : return 415
        case .unprocessableEntity       : return 422
        case .internalServerError       : return 500
        case .notImplemented            : return 501
        case .badGateway                : return 502
        case .serviceUnavailable        : return 503
        case .gatewayTimeout            : return 504
        case .httpVersionNotSupported   : return 505
        case .other(let value)          : return value
        }
    }
    
    /// The type this status code falls under, such as 2xx (success), 4xx (client error) or 5xx (server error)
    public var type: StatusCodeType {
        switch rawValue {
        case 100..<200: return .informational
        case 200..<300: return .success
        case 300..<400: return .redirect
        case 400..<500: return .clientError
        case 500..<600: return .serverError
        default       : return .invalid
        }
    }
    
    
    public var localizedDescription: String {
        return HTTPURLResponse.localizedString(forStatusCode: rawValue)
    }
    
    public init(rawValue: Int) {
        if let statusCode = StatusCode.predefined.first(where: { $0.rawValue == rawValue }) {
            self = statusCode
        } else {
            self = StatusCode.other(rawValue)
        }
    }
    
    /// Returns any errors associated with this status code. This will always return a value unless the status code is either 1xx (informational), 2xx (success) or 3xx (rediect).
    public var httpError: HTTPError? {
        switch type {
        case .clientError:
            return HTTPError.clientError(self)
        case .serverError:
            return HTTPError.serverError(self)
        case .invalid:
            return HTTPError.invalidStatusCode(self)
        case .success, .redirect, .informational:
            return nil
        }
    }
    
    public static func == (lhs: StatusCode, rhs: StatusCode) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension StatusCode: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        self = StatusCode(rawValue: rawValue)
    }
}

/// The type of status code which refers to its number grouping such as 2xx (success) or 4xx (client error)
public enum StatusCodeType: Equatable {
    /// 1xx
    case informational
    /// 2xx
    case success
    /// 3xx
    case redirect
    /// 4xx
    case clientError
    /// 5xx
    case serverError
    /// Other
    case invalid
    
    /// Returns true if the response is typically considered as valid. This includes 1xx (informational), 2xx (success) and 3xx (redirect) response codes.
    public var isSuccessful: Bool {
        switch self {
        case .informational : return true
        case .success       : return true
        case .redirect      : return true
        case .clientError   : return false
        case .serverError   : return false
        case .invalid       : return false
        }
    }
}
