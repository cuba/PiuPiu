//
//  HTTPMethod.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2018-12-02.
//  Copyright © 2018 Jacob Sikorski. All rights reserved.
//

import Foundation
import Alamofire

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
