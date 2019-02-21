//
//  HTTPMethod.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2018-12-02.
//  Copyright © 2018 Jacob Sikorski. All rights reserved.
//

import Foundation


/// The HTTP Method to use when sending the request.
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
    
    var requiresBody: Bool {
        switch self {
        case .options:  return false
        case .get:      return false
        case .head:     return false
        case .post:     return true
        case .put:      return true
        case .patch:    return true
        case .delete:   return false
        case .trace:    return false
        case .connect:  return false
        }
    }
}
