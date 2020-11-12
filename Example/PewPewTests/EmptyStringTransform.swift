//
//  EmptyStringTransform.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
import PiuPiu

class EmptyStringTransformTests: XCTestCase {
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
    
    func testFromJSONTransform_EmptyString() {
        let transform = EmptyStringTransform()
        
        do {
            // When
            let value = try transform.from(json: "", codingPath: [])
            XCTAssertNil(value)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testFromJSONTransform_NonEmptyString() {
        let transform = EmptyStringTransform()
        
        do {
            // When
            let value = try transform.from(json: "test", codingPath: [])
            XCTAssertEqual(value, "test")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testToJSONTransform_EmptyString() {
        let transform = EmptyStringTransform()
        
        do {
            // When
            let value = try transform.toJSON("", codingPath: [])
            XCTAssertNil(value)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testToJSONTransform_NonEmptyString() {
        let transform = EmptyStringTransform()
        
        do {
            // When
            let value = try transform.toJSON("test", codingPath: [])
            XCTAssertEqual(value, "test")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testDecodingFullExample_WithKey() {
        // Given
        let jsonObject: [String: Any?] = ["requiredKey": "", "optionalKey": ""]
        let data = try! JSONSerialization.data(withJSONObject: jsonObject)
        let decoder = JSONDecoder()
        
        do {
            // When
            let model = try decoder.decode(ExampleDecodingModel.self, from: data)
            
            // Then
            XCTAssertNil(model.stringWithRequiredKey)
            XCTAssertNil(model.stringWithOptionalKey)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testDecodingFullExample_WithoutKey() {
        // Given
        let jsonObject: [String: Any?] = ["requiredKey": ""]
        let data = try! JSONSerialization.data(withJSONObject: jsonObject)
        let decoder = JSONDecoder()
        
        do {
            // When
            let model = try decoder.decode(ExampleDecodingModel.self, from: data)
            
            // Then
            XCTAssertNil(model.stringWithRequiredKey)
            XCTAssertNil(model.stringWithOptionalKey)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
