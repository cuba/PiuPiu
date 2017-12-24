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
    
    func error(cause: Error?) -> Error? {
        switch self {
        case .badRequest:           return ClientError.badRequest(cause: cause)
        case .unauthorized:         return ClientError.unauthorized(cause: cause)
        case .forbidden:            return ClientError.forbidden(cause: cause)
        case .notFound:             return ClientError.notFound(cause: cause)
        case .conflict:             return ClientError.conflict(cause: cause)
        case .unprocessableEntity:  return ClientError.unprocessableEntity(cause: cause)
        case .internalServerError:  return ServerError.internalServerError(cause: cause)
        default:                    return nil
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
    public var serverProvider: ServerProvider
    public var sessionManager: SessionManager
    
    public init(serverProvider: ServerProvider, requestAdapter: RequestAdapter? = nil, requestRetrier: RequestRetrier? = nil) {
        self.serverProvider = serverProvider
        self.sessionManager = SessionManager()
        sessionManager.adapter = requestAdapter
        sessionManager.retrier = requestRetrier
    }
    
    open func send(_ request: Request, responseHandler: @escaping ResponseHandler, completionHandler: CompletionHandler? = nil) {
        
        do {
            let alamofireRequest = try self.alamofireRequest(from: request)
            send(alamofireRequest, responseHandler: responseHandler, completionHandler: completionHandler)
        } catch let error {
            responseHandler(nil, error)
        }
    }
    
    open func send(_ alamofireRequest: Alamofire.DataRequest, responseHandler: @escaping ResponseHandler, completionHandler: CompletionHandler? = nil) {
        
        #if DEBUG
        Logger.log(alamofireRequest)
        #endif
        
        guard NetworkReachabilityManager.shared.isReachable else {
            responseHandler(nil, NetworkError.noConnection)
            return
        }
        
        alamofireRequest.validate().responseJSON { dataResponse in
            let result = dataResponse.result
            
            #if DEBUG
            Logger.log(dataResponse)
            #endif
            
            // Ensure there is a status code (ex: 200)
            guard let statusCode = dataResponse.response?.statusCode else {
                let error = ResponseError.unknown(cause: dataResponse.error)
                responseHandler(result, error)
                completionHandler?()
                return
            }
            
            // Ensure there are no errors. If there are, map them to our errors
            guard dataResponse.error == nil else {
                guard let statusCode = StatusCode(rawValue: statusCode), let responseError = statusCode.error(cause: dataResponse.error) else {
                    let error = ResponseError.unknown(cause: dataResponse.error)
                    responseHandler(result, error)
                    completionHandler?()
                    return
                }
                
                responseHandler(result.value, responseError)
                completionHandler?()
                return
            }
            
            responseHandler(result.value, nil)
            completionHandler?()
        }
    }
    
    private func alamofireRequest(from request: Request) throws -> Alamofire.DataRequest {
        
        do {
            let url = try self.url(from: request)
            let method = request.method.alamofireMethod
            return sessionManager.request(url, method: method, parameters: request.parameters, encoding: URLEncoding.default, headers: request.headers)
        } catch let error {
            throw ClientError.invalidURL(cause: error)
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
