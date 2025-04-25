//
//  TimeZoneTransformTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Testing
import Foundation
import PiuPiu

struct TimeZoneTransformTests {
  struct ExampleModel: Codable {
    enum CodingKeys: String, CodingKey {
      case timeZoneId
    }
    
    let timeZone: TimeZone
    
    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.timeZone = try container.decode(using: TimeZoneTransform(), forKey: .timeZoneId)
    }
    
    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(timeZone, forKey: .timeZoneId, using: TimeZoneTransform())
    }
  }
  
  @Test func fromJSONTransform() throws {
    let transform = TimeZoneTransform()
    let identifier = "America/Montreal"
    
    // When
    let value = try transform.from(json: identifier, codingPath: [])
    #expect(value == TimeZone(identifier: "America/Montreal")!)
  }
  
  @Test func toJSONTransform() throws {
    // Given
    let transform = TimeZoneTransform()
    let timeZone = TimeZone(identifier: "America/Montreal")!
    
    // When
    let identifier = try transform.toJSON(timeZone, codingPath: [])
    #expect(identifier == "America/Montreal")
  }
  
  @Test func decodingFullExample() throws {
    // Given
    let jsonObject: [String: Any?] = ["timeZoneId": "America/Montreal"]
    let data = try! JSONSerialization.data(withJSONObject: jsonObject)
    let decoder = JSONDecoder()
    
    // When
    let model = try decoder.decode(ExampleModel.self, from: data)
    
    // Then
    #expect(model.timeZone == TimeZone(identifier: "America/Montreal")!)
  }
}
