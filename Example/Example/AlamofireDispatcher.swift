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

class AlamofireDispatcher: DataDispatcher {
    var sessionManager: SessionManager
    
    /// Initialize this `Dispatcher` with a `URLRequestProvider`.
    ///
    /// - Parameter urlRequestProvider: The server provider that will give the dispatcher the `baseURL`.
    init(sessionManager: SessionManager = SessionManager()) {
        self.sessionManager = sessionManager
    }
    
    func dataFuture(from urlRequest: URLRequest) -> ResponseFuture<Response<Data?>> {
        return ResponseFuture<Response<Data?>>() { [weak self] future in
            guard let self = self else { return }
            
            self.sessionManager.request(urlRequest).response(completionHandler: { dataResponse in
                // Ensure we don't have an error
                if let error = dataResponse.error {
                    DispatchQueue.main.async {
                        future.fail(with: error)
                    }
                    
                    return
                }
                
                // Ensure there is an http response
                guard let httpResponse = dataResponse.response else {
                    let error = ResponseError.unknown
                    future.fail(with: error)
                    return
                }
                
                // Create the response
                let statusCode = StatusCode(rawValue: httpResponse.statusCode)
                let responseError = statusCode.makeError()
                let response = Response(data: dataResponse.data, httpResponse: httpResponse, urlRequest: urlRequest, statusCode: statusCode, error: responseError)

                DispatchQueue.main.async {
                    future.update(progress: 1)
                    future.succeed(with: response)
                }
            })
        }
    }
}
