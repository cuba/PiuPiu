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
        let httpBody = request.httpBody
        
        print("")
        print("===============================================")
        print("REQUEST: [\(method)] \(url)")
        
        // Print headers
        if let headers = request.allHTTPHeaderFields {
            log(headers: headers)
        }
        
        if let body = httpBody {
            if let string = NSString(data: body, encoding: String.Encoding.utf8.rawValue) {
                print("REQUEST BODY: \(string)")
            } else {
                do {
                    if let jsonData = try getJsonObject(body) {
                        print("REQUEST BODY: \(jsonData)")
                    }
                } catch let error {
                    print("REQUEST BODY: [PARSING FAILED: \(error.localizedDescription)]")
                }
            }
        } else {
            print("REQUEST BODY: [EMPTY]")
        }
        print("===============================================")
    }
    
    static func log(_ dataResponse: Alamofire.DataResponse<Data>) {
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
        
        if let body = dataResponse.data {
            if let string = NSString(data: body, encoding: String.Encoding.utf8.rawValue) {
                print("RESPONSE BODY: \(string)")
            } else {
                do {
                    if let jsonData = try getJsonObject(body) {
                        print("RESPONSE BODY: \(jsonData)")
                    }
                } catch let error {
                    print("RESPONSE BODY: [PARSING FAILED: \(error.localizedDescription)]")
                }
            }
        } else {
            print("REQUEST BODY: [EMPTY]")
        }
        
        print("===============================================")
    }
    
    static func getJsonObject(_ jsonData: Data) throws -> Any? {
        return try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers)
    }
    
    static func log(headers: [AnyHashable: Any]) {
        print("HEADERS:")
        headers.forEach { (key, value) in print("\(key): \(value)") }
    }
}
#endif
