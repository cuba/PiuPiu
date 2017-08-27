//
//  Logger.swift
//  NetworkKit
//
//  Created by Jacob Sikorski on 2017-08-26.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

#if DEBUG
import Alamofire

class Logger {
    static func log(_ dataRequest: Alamofire.DataRequest) {
        guard let request = dataRequest.request else { return }
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "UNKNOWN URL"
        
        print("")
        print("===============================================")
        print("REQUEST: [\(method)] \(url)")
        
        // Print headers
        if let headers = request.allHTTPHeaderFields {
            log(headers: headers)
        }
        print("===============================================")
    }
    
    static func log(_ dataResponse: Alamofire.DataResponse<Any>) {
        guard let request = dataResponse.request else { return }
        guard let response = dataResponse.response else { return }
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "UNKNOWN URL"
        let statusCode = response.statusCode
        
        print("")
        print("===============================================")
        print("RESPONSE: (\(statusCode)) [\(method)] \(url)")
        
        // Print headers
        log(headers: response.allHeaderFields)
        
        if let value = dataResponse.result.value {
            print("DATA: \(value)")
        } else {
            print("DATA: [EMPTY]")
        }
        
        print("===============================================")
    }
    
    static func log(headers: [AnyHashable: Any]) {
        print("HEADERS:")
        headers.forEach { (key, value) in print("\(key): \(value)") }
    }
}
#endif
