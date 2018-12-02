//
//  NetworkDispatcher.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation
import Alamofire

public typealias ResponseHandler = (Any?, [AnyHashable: Any]?, Error?) -> Void

open class NetworkDispatcher {
    public weak var serverProvider: ServerProvider?
    public var sessionManager: SessionManager
    
    public init(serverProvider: ServerProvider, requestAdapter: RequestAdapter? = nil, requestRetrier: RequestRetrier? = nil) {
        self.serverProvider = serverProvider
        self.sessionManager = SessionManager()
        sessionManager.adapter = requestAdapter
        sessionManager.retrier = requestRetrier
    }
    
    open func send(_ request: Request, responseHandler: @escaping ResponseHandler) {
        guard let serverProvider = self.serverProvider else { return }
        
        do {
            let alamofireRequest = try self.alamofireRequest(from: request, serverProvider: serverProvider)
            NetworkDispatcher.send(alamofireRequest, responseHandler: responseHandler)
        } catch let error {
            responseHandler(nil, nil, error)
        }
    }
    
    public static func send(_ alamofireRequest: Alamofire.DataRequest, responseHandler: @escaping ResponseHandler) {
        
        #if DEBUG
        Logger.log(alamofireRequest)
        #endif
        
        guard NetworkReachabilityManager.shared.isReachable else {
            responseHandler(nil, nil, NetworkError.noConnection)
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
                responseHandler(result, nil, error)
                return
            }
            
            // Ensure there are no errors. If there are, map them to our errors
            guard dataResponse.error == nil else {
                guard let statusCode = StatusCode(rawValue: statusCode), let responseError = statusCode.error(cause: dataResponse.error) else {
                    let error = ResponseError.unknown(cause: dataResponse.error)
                    responseHandler(result, nil, error)
                    return
                }
                
                responseHandler(result.value, nil, responseError)
                return
            }
            
            responseHandler(result.value, nil, nil)
        }
    }
    
    private func alamofireRequest(from request: Request, serverProvider: ServerProvider) throws -> Alamofire.DataRequest {
        do {
            let url = try serverProvider.url(from: request)
            let method = request.method.alamofireMethod
            return sessionManager.request(url, method: method, parameters: request.parameters, encoding: request.parameterEncoding, headers: request.headers)
        } catch let error {
            throw ClientError.invalidURL(cause: error)
        }
    }
}
