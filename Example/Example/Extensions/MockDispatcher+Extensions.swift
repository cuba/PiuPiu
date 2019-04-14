//
//  MockDispatcher+Extensions.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-04-14.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import NetworkKit

extension MockDispatcher {
    static func makeDispatcher<T: Encodable>(with response: T, status: StatusCode = .ok) throws -> MockDispatcher {
        let url = URL(string: "https://jsonplaceholder.typicode.com")!
        let dispatcher = MockDispatcher(baseUrl: url, mockStatusCode: status)
        try dispatcher.setMockData(response)
        
        return dispatcher
    }
}


