//
//  NetworkDispatcher.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation
import Alamofire

public typealias SuccessHandler = (Any?) -> Void
public typealias ErrorHandler = (Error) -> Void
public typealias ResponseHandler = (Any?, Error?) -> Void
public typealias CompletionHandler = () -> Void

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
    
    var alamofireMethod: Alamofire.HTTPMethod {
        switch self {
        case .options:  return .options
        case .get:      return .get
        case .head:     return .head
        case .post:     return .post
        case .put:      return .put
        case .patch:    return .patch
        case .delete:   return .delete
        case .trace:    return .trace
        case .connect:  return .connect
        }
    }
}

public enum StatusCode: Int {
    case ok             = 200
    case created        = 201
    case noData         = 204
    case badRequest     = 400
    case unauthorized   = 401
    case forbidden      = 403
    case notFound       = 404
    case conflict       = 409
    
    case unprocessableEntity = 422
    case internalServerError = 500
    
    func responseError(cause: Error?) -> ResponseError? {
        switch self {
        case .badRequest:           return .badRequest(cause: cause)
        case .unauthorized:         return .unauthorized(cause: cause)
        case .forbidden:            return .forbidden(cause: cause)
        case .notFound:             return .notFound(cause: cause)
        case .conflict:             return .conflict(cause: cause)
        case .unprocessableEntity:  return .unprocessableEntity(cause: cause)
        case .internalServerError:  return .internalServerError(cause: cause)
        default:                    return nil
        }
    }
}

public enum RequestError: Error {
    case invalidURL(cause: Error?)
}

extension RequestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "RequestError.Description.InvalidURL".localized
        }
    }
}

public enum ResponseError: Error {
    case badRequest(cause: Error?)
    case unauthorized(cause: Error?)
    case forbidden(cause: Error?)
    case notFound(cause: Error?)
    case conflict(cause: Error?)
    case unprocessableEntity(cause: Error?)
    case internalServerError(cause: Error?)
    case unknown(cause: Error?)
}

extension ResponseError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .badRequest:           return "ResponseError.Description.InvalidURL".localized
        case .unauthorized:         return "ResponseError.Description.Unauthorized".localized
        case .forbidden:            return "ResponseError.Description.Forbidden".localized
        case .notFound:             return "ResponseError.Description.NotFound".localized
        case .conflict:             return "ResponseError.Description.Conflict".localized
        case .unprocessableEntity:  return "ResponseError.Description.UnprocessableEntity".localized
        case .internalServerError:  return "ResponseError.Description.InternalServerError".localized
        case .unknown:              return "ResponseError.Description.Unknown".localized
        }
    }
}

public protocol Request {
    var method: HTTPMethod { get }
    var path:   String { get }
    var queryItems: [URLQueryItem]? { get }
    var parameters: [String : Any]? { get }
    var headers: [String : String]? { get }
}

public struct JSONRequest: Request {
    public var method: HTTPMethod
    public var path:   String
    public var queryItems: [URLQueryItem]?
    public var parameters: [String: Any]?
    public var headers: [String: String]?
    
    public init(method: HTTPMethod, path: String, queryItems: [URLQueryItem]? = nil, parameters: [String: Any]? = nil, headers: [String: String]? = nil) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.parameters = parameters
        self.headers = headers
    }
}

open class NetworkDispatcher {
    var serverProvider: ServerProvider
    var sessionManager: SessionManager
    
    public init(serverProvider: ServerProvider, requestAdapter: RequestAdapter? = nil) {
        self.serverProvider = serverProvider
        self.sessionManager = SessionManager()
        sessionManager.adapter = requestAdapter
    }
    
    open func send(_ request: Request, responseHandler: @escaping ResponseHandler) {
        
        do {
            let alamofireRequest = try self.alamofireRequest(from: request)
            send(alamofireRequest, responseHandler: responseHandler)
        } catch let error {
            responseHandler(nil, error)
        }
    }
    
    open func send(_ alamofireRequest: Alamofire.DataRequest, responseHandler: @escaping ResponseHandler) {
        
        #if DEBUG
        Logger.log(alamofireRequest)
        #endif
        
        alamofireRequest.validate().responseJSON { dataResponse in
            let result = dataResponse.result
            
            #if DEBUG
            Logger.log(dataResponse)
            #endif
            
            // Ensure there is a status code (ex: 200)
            guard let statusCode = dataResponse.response?.statusCode else {
                let error = ResponseError.unknown(cause: dataResponse.error)
                responseHandler(result, error)
                return
            }
            
            // Ensure there are no errors. If there are, map them to our errors
            guard dataResponse.error == nil else {
                guard let statusCode = StatusCode(rawValue: statusCode), let responseError = statusCode.responseError(cause: dataResponse.error) else {
                    let error = ResponseError.unknown(cause: dataResponse.error)
                    responseHandler(result, error)
                    return
                }
                
                responseHandler(result.value, responseError)
                return
            }
            
            responseHandler(result.value, nil)
        }
    }
    
    private func alamofireRequest(from request: Request) throws -> Alamofire.DataRequest {
        
        do {
            let url = try self.url(from: request)
            let method = request.method.alamofireMethod
            return sessionManager.request(url, method: method, parameters: request.parameters, encoding: URLEncoding.default, headers: request.headers)
        } catch let error {
            throw RequestError.invalidURL(cause: error)
        }
    }
    
    private func url(from request: Request) throws -> URL {
        
        var urlComponents = URLComponents(url: serverProvider.baseURL, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = request.queryItems
        urlComponents?.path = request.path
        
        if let url = try urlComponents?.asURL() {
            return url
        } else {
            throw URLError(.badURL)
        }
    }
}
