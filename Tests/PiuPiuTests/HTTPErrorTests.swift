//
//  HTTPErrorTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2021-10-14.
//  Copyright © 2021 Jacob Sikorski. All rights reserved.
//

import XCTest
import PiuPiu

class HTTPErrorTests: XCTestCase {
    func testLocalizableError() throws {
        let error = HTTPError.clientError(.badRequest)
        XCTAssertEqual(error.localizedDescription, HTTPURLResponse.localizedString(forStatusCode: 400))
    }
}
