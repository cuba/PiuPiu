//
//  Request.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-16.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A protocol that can be used when you need to dynamically create the URLRequest with a shared base url
/// Will be used in conjucntion with `ServerProvider`
public protocol Request {
    /// The function that will create the URLRequest
    func urlRequest(withBaseURL baseURL: URL) throws -> URLRequest
}
