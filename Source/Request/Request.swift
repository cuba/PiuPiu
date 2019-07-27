//
//  Request.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-16.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public protocol Request {
    func urlRequest(withBaseURL baseURL: URL) throws -> URLRequest
}
