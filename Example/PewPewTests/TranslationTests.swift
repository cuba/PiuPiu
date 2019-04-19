//
//  TranslationTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-04-19.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import PewPew
@testable import Example

class TranslationTests: XCTestCase {
    func testStringLocalizedKeyNotFound() {
        let result = "Test".localized()
        XCTAssertEqual(result, "Test")
    }
    
    func testStringLocalizedResponseError() {
        let result = ResponseError.unknown(cause: nil).localizedDescription
        XCTAssertEqual(result, "Got an unexpected response from the server. If this issue persists, please contact technical support.")
    }
}
