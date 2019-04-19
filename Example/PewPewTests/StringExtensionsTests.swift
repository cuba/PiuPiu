//
//  StringExtensionsTests.swift
//  NetworkKitTests
//
//  Created by Jacob Sikorski on 2019-04-19.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import PewPew

class StringExtensionsTests: XCTestCase {

    func testLocalized() {
        let result = "Test".localized()
        XCTAssertEqual("Test", result)
    }
}
