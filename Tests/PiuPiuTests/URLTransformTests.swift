//
//  URLTransformTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Testing
import Foundation
import PiuPiu

struct URLTransformTests {
  @Test func fromJSONTransform() throws {
    let transform = URLTransform()
    let json = "https://example.com"
    
    // When
    let value = try transform.from(json: json, codingPath: [])
    
    // Then
    #expect(value == URL(string: "https://example.com")!)
  }
  
  @Test func toJSONTransform() throws {
    // Given
    let transform = URLTransform()
    let value = URL(string: "https://example.com")!
    
    // When
    let json = try transform.toJSON(value, codingPath: [])
    
    // Then
    #expect(json == "https://example.com")
  }
}
