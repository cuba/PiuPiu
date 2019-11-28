//
//  TimeZoneTransformTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
import PiuPiu

class TimeZoneTransformTests: XCTestCase {
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
    
    func testFromJSONTransform() {
        let transform = TimeZoneTransform()
        let identifier = "America/Montreal"
        
        do {
            // When
            let value = try transform.transform(json: identifier)
            XCTAssertEqual(value, TimeZone(identifier: "America/Montreal")!)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testToJSONTransform() {
        // Given
        let transform = TimeZoneTransform()
        let timeZone = TimeZone(identifier: "America/Montreal")!
        
        do {
            // When
            let identifier = try transform.transform(value: timeZone)
            XCTAssertEqual(identifier, "America/Montreal")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testDecodingFullExample() {
        // Given
        let jsonObject: [String: Any?] = ["timeZoneId": "America/Montreal"]
        let data = try! JSONSerialization.data(withJSONObject: jsonObject)
        let decoder = JSONDecoder()
        
        do {
            // When
            let model = try decoder.decode(ExampleModel.self, from: data)
            
            // Then
            XCTAssertEqual(model.timeZone, TimeZone(identifier: "America/Montreal")!)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
