//
//  KeyedEncodingContainerTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
import PiuPiu

class KeyedEncodingContainerTests: XCTestCase {
    class FakeEncodingTransform: EncodingTransform {
        func toJSON(_ value: Int, codingPath: [CodingKey]) throws -> String {
            return "\(value)"
        }
    }
    
    struct TestModel: Encodable {
        enum CodingKeys: String, CodingKey {
            case required
            case optional
        }
        
        let required: Int
        let optional: Int?
        
        init(required: Int, optional: Int?) {
            self.required = required
            self.optional = optional
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(required, forKey: .required, using: FakeEncodingTransform())
            try container.encodeIfPresent(optional, forKey: .optional, using: FakeEncodingTransform())
        }
    }
    
    func testEncoding_WhenAllPresent() {
        // Given
        let encodable = TestModel(required: 1234567890, optional: 1234567890)
        let encoder = JSONEncoder()
        
        do {
            // When
            let data = try encoder.encode(encodable)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any?]
            let required = jsonObject["required"] as? String
            let optional = jsonObject["optional"] as? String
            
            // Then
            XCTAssertEqual(required, "1234567890")
            XCTAssertEqual(optional, "1234567890")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testDecoding_WhenOptionalMissing() {
        // Given
        let encodable = TestModel(required: 1234567890, optional: nil)
        let encoder = JSONEncoder()
        
        do {
            // When
            let data = try encoder.encode(encodable)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any?]
            let required = jsonObject["required"] as? String
            
            // Then
            XCTAssertEqual(required, "1234567890")
            XCTAssertNil(jsonObject.index(forKey: "optional"))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}


