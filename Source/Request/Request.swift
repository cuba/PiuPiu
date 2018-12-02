//
//  Request.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2018-12-02.
//  Copyright © 2018 Jacob Sikorski. All rights reserved.
//

import Foundation
import Alamofire

public protocol Request {
    var method: HTTPMethod { get }
    var path:   String { get }
    var queryItems: [URLQueryItem]? { get }
    var parameters: [String: Any]? { get }
    var headers: [String: String]? { get }
    var parameterEncoding: ParameterEncoding { get }
}
