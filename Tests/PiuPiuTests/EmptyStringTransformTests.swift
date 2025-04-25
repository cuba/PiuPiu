//
//  EmptyStringTransformTests.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-04-21.
//

import Testing
import Foundation
import PiuPiu

struct EmptyStringTransformTests {
  struct ExampleDecodingModel: Codable {
    enum CodingKeys: String, CodingKey {
      case requiredKey
      case optionalKey
    }
    
    let stringWithRequiredKey: String?
    let stringWithOptionalKey: String?
    
    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.stringWithRequiredKey = try container.decode(using: EmptyStringTransform(), forKey: .requiredKey)
      self.stringWithOptionalKey = try container.decodeIfPresent(using: EmptyStringTransform(), forKey: .optionalKey) ?? nil
    }
    
    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encodeIfPresent(stringWithRequiredKey, forKey: .requiredKey, using: EmptyStringTransform())
    }
  }
  
  @Test func fromJSONWithEmptyString() throws {
    let transform = EmptyStringTransform()
    let value = try transform.from(json: "", codingPath: [])
    #expect(value == nil)
  }
  
  @Test func fromJSONWithNonEmptyString() throws {
    let transform = EmptyStringTransform()
    let value = try transform.from(json: "test", codingPath: [])
    #expect(value == "test")
  }
  
  @Test func toJSONWithEmptyString() throws {
    let transform = EmptyStringTransform()
    let value = try transform.toJSON("", codingPath: [])
    #expect(value == nil)
  }
  
  @Test func toJSONWithNonEmptyString() throws {
    let transform = EmptyStringTransform()
    let value = try transform.toJSON("test", codingPath: [])
    #expect(value == "test")
  }
  
  @Test func decodingFullExampleWithKey() throws {
    // Given
    let jsonObject: [String: Any?] = ["requiredKey": "", "optionalKey": ""]
    let data = try! JSONSerialization.data(withJSONObject: jsonObject)
    let decoder = JSONDecoder()
    let model = try decoder.decode(ExampleDecodingModel.self, from: data)
    
    // Then
    #expect(model.stringWithRequiredKey == nil)
    #expect(model.stringWithOptionalKey == nil)
  }
  
  @Test func decodingFullExampleWithoutKey() throws {
    // Given
    let jsonObject: [String: Any?] = ["requiredKey": ""]
    let data = try! JSONSerialization.data(withJSONObject: jsonObject)
    let decoder = JSONDecoder()
    let model = try decoder.decode(ExampleDecodingModel.self, from: data)
    
    // Then
    #expect(model.stringWithRequiredKey == nil)
    #expect(model.stringWithOptionalKey == nil)
  }
}
