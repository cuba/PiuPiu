//
//  MockJSONFileAdapter.swift
//  PewPewTests
//
//  Created by Jakub Sikorski on 2022-01-19.
//  Copyright © 2022 Jacob Sikorski. All rights reserved.
//

import Foundation
import PiuPiu

class MockHTTPResponseAdapter: URLResponseAdapter {
    static var success = MockHTTPResponseAdapter(statusCode: .ok)

    let statusCode: StatusCode

    init(statusCode: StatusCode) {
        self.statusCode = statusCode
    }

    func adapt(urlResponse: URLResponse, for urlRequest: URLRequest, with callback: @escaping (URLResponse) throws -> Void) throws {
        if let url = urlResponse.url, let newResponse = HTTPURLResponse(url: url, statusCode: statusCode.rawValue, httpVersion: nil, headerFields: nil) {
            try callback(newResponse)
        } else {
            try callback(urlResponse)
        }
    }
}
