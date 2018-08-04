//
//  ServerProvider.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

public protocol ServerProvider: class {
    var baseURL: URL { get }
}

extension ServerProvider {
    func url(from request: Request) throws -> URL {
        
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = request.queryItems
        urlComponents?.path = request.path
        
        if let url = try urlComponents?.asURL() {
            return url
        } else {
            throw URLError(.badURL)
        }
    }
}
