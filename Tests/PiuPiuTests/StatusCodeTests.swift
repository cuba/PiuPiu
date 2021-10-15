//
//  StatusCodeTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2021-10-14.
//  Copyright © 2021 Jacob Sikorski. All rights reserved.
//

import XCTest
import PiuPiu

class StatusCodeTests: XCTestCase {
    func testHTTPError() throws {
        let statusCode = StatusCode.badRequest
        
        switch statusCode.httpError {
        case .clientError(let errorStatusCode):
            XCTAssertEqual(statusCode, errorStatusCode)
        default:
            XCTFail("Invalid error returned")
        }
        
    }
}
