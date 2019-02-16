//
//  NetworkDispatcher.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation
import Alamofire

public typealias ResponseHandler = (Data?, [AnyHashable: Any]?, Error?) -> Void

open class NetworkDispatcher {
    public weak var serverProvider: ServerProvider?
    public var sessionManager: SessionManager
    
    public init(serverProvider: ServerProvider, requestAdapter: RequestAdapter? = nil, requestRetrier: RequestRetrier? = nil) {
        self.serverProvider = serverProvider
        self.sessionManager = SessionManager()
        sessionManager.adapter = requestAdapter
        sessionManager.retrier = requestRetrier
    }

    open func response(from request: Request) -> Promise<SuccessResponse<Data?>, ErrorResponse<Data?>> {
        return Promise<SuccessResponse<Data?>, ErrorResponse>(action: { [weak self] promise in
            self?.send(request) { data, headers, error in
                if let error = error {
                    // Check if we have an error
                    // TODO: Allow the user to serialize an error object from the response
                    promise.fail(with: (error, data, headers))
                } else {
                    // We have a response object. Let's return it.
                    promise.succeed(with: (data, headers ?? [:]))
                }
            }
        })
    }
    
    private func send(_ request: Request, responseHandler: @escaping ResponseHandler) {
        guard let serverProvider = self.serverProvider else { return }
        
        do {
            let alamofireRequest = try self.alamofireRequest(from: request, serverProvider: serverProvider)
            NetworkDispatcher.send(alamofireRequest, responseHandler: responseHandler)
        } catch let error {
            responseHandler(nil, nil, error)
        }
    }
    
    private static func send(_ alamofireRequest: Alamofire.DataRequest, responseHandler: @escaping ResponseHandler) {
        
        #if DEBUG
        Logger.log(alamofireRequest)
        #endif
        
        guard NetworkReachabilityManager.shared.isReachable else {
            responseHandler(nil, nil, NetworkError.noConnection)
            return
        }
        
        alamofireRequest.validate().responseData() { data in
            #if DEBUG
            Logger.log(data)
            #endif
            
            // Ensure there is a status code (ex: 200)
            guard let statusCode = data.response?.statusCode else {
                let error = ResponseError.unknown(cause: data.error)
                responseHandler(data.data, nil, error)
                return
            }
            
            // Ensure there are no errors. If there are, map them to our errors
            guard data.error == nil else {
                guard let statusCode = StatusCode(rawValue: statusCode), let responseError = statusCode.error(cause: data.error) else {
                    let error = ResponseError.unknown(cause: data.error)
                    responseHandler(data.data, nil, error)
                    return
                }
                
                responseHandler(data.data, nil, responseError)
                return
            }
            
            responseHandler(data.data, nil, nil)
        }
    }
    
    private func alamofireRequest(from request: Request, serverProvider: ServerProvider) throws -> Alamofire.DataRequest {
        do {
            let url = try serverProvider.url(from: request)
            let method = request.method.alamofireMethod
            return sessionManager.request(url, method: method, parameters: request.body, encoding: request.parameterEncoding, headers: request.headers)
        } catch let error {
            throw ClientError.invalidURL(cause: error)
        }
    }
}
