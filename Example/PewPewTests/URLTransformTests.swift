//
//  URLTransformTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
import PiuPiu

class URLTransformTests: XCTestCase {
    func testFromJSONTransform() {
        let transform = URLTransform()
        let json = "https://example.com"
        
        do {
            // When
            let value = try transform.transform(json: json)
            XCTAssertEqual(value, URL(string: "https://example.com")!)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testToJSONTransform() {
        // Given
        let transform = URLTransform()
        let value = URL(string: "https://example.com")!
        
        do {
            // When
            let json = try transform.transform(value: value)
            XCTAssertEqual(json, "https://example.com")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}
