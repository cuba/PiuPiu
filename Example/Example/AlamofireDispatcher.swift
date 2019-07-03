//
//  AlamofireDispatcher.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-04-12.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import PiuPiu
import Alamofire

class AlamofireDispatcher: Dispatcher {
    weak var serverProvider: ServerProvider?
    var sessionManager: SessionManager
    
    /// Initialize this `Dispatcher` with a `ServerProvider`.
    ///
    /// - Parameter serverProvider: The server provider that will give the dispatcher the `baseURL`.
    init(serverProvider: ServerProvider) {
        self.serverProvider = serverProvider
        self.sessionManager = SessionManager()
    }
    
    func future(from request: PiuPiu.Request) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { [weak self] future in
            guard let self = self else { return }
            
            guard let serverProvider = self.serverProvider else {
                throw RequestError.missingServerProvider
            }
            
            let urlRequest = try serverProvider.urlRequest(from: request)
            
            self.sessionManager.request(urlRequest).response(completionHandler: { dataResponse in
                // Ensure there is an http response
                guard let httpResponse = dataResponse.response else {
                    let error = ResponseError.unknown(cause: dataResponse.error)
                    future.fail(with: error)
                    return
                }
                
                // Create the response
                let error = dataResponse.error
                let statusCode = StatusCode(rawValue: httpResponse.statusCode)
                let responseError = statusCode.makeError(cause: error)
                let response = Response(data: dataResponse.data, httpResponse: httpResponse, urlRequest: urlRequest, statusCode: statusCode, error: responseError)

                future.update(progress: 1)
                future.succeed(with: response)
            })
        }
    }
}
