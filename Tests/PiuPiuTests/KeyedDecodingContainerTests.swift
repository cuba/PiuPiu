//
//  KeyedDecodingContainerTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Testing
import Foundation
import PiuPiu

struct KeyedDecodingContainerTests {
  class FakeDecodingTransform: DecodingTransform {
    func from(json: String, codingPath: [CodingKey]) throws -> Int {
      return Int(json)!
    }
  }
  
  struct TestModel: Decodable {
    enum CodingKeys: String, CodingKey {
      case required
      case optional
    }
    
    let required: Int
    let optional: Int?
    
    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.required = try container.decode(using: FakeDecodingTransform(), forKey: .required)
      self.optional = try container.decodeIfPresent(using: FakeDecodingTransform(), forKey: .optional)
    }
  }
  
  @Test func decodingWhenAllPresent() throws {
    // Given
    let jsonObject: [String: Any?] = [
      "required": "1234567890",
      "optional": "1234567890"
    ]
    
    let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
    
    // When
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(TestModel.self, from: data)
    
    // Then
    #expect(decoded.required == 1234567890)
    #expect(decoded.optional == 1234567890)
  }
  
  @Test func decodingWhenOptionalMissing() throws {
    // Given
    let jsonObject: [String: Any?] = [
      "required": "1234567890",
      "optional": nil
    ]
    
    let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
    
    // When
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(TestModel.self, from: data)
    
    // Then
    #expect(decoded.required == 1234567890)
    #expect(decoded.optional == nil)
  }
  
  @Test func decodingWhenRequiredMissing() throws {
    // Given
    let jsonObject: [String: Any?] = [
      "required": nil,
      "optional": "1234567890"
    ]
    
    let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
    
    // When
    let decoder = JSONDecoder()
    
    // Then
    #expect(throws: DecodingError.self, performing: {
      try decoder.decode(TestModel.self, from: data)
    })
  }
  
  @Test func decodingWhenAllMissing() throws {
    // Given
    let jsonObject: [String: Any?] = [
      "required": nil,
      "optional": nil
    ]
    
    let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
    
    // When
    let decoder = JSONDecoder()
    
    // Then
    #expect(throws: DecodingError.self, performing: {
      try decoder.decode(TestModel.self, from: data)
    })
  }
  
  @Test func decodingWhenNoKeys() throws {
    // Given
    let jsonObject: [String: Any?] = [:]
    let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
    
    // When
    let decoder = JSONDecoder()
    
    // Then
    #expect(throws: DecodingError.self, performing: {
      try decoder.decode(TestModel.self, from: data)
    })
  }
}
