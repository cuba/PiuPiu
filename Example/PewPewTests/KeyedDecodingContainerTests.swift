//
//  KeyedDecodingContainerTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
import PiuPiu

class KeyedDecodingContainerTests: XCTestCase {
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
    
    func testDecoding_WhenAllPresent() {
        do {
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
            XCTAssertEqual(decoded.required, 1234567890)
            XCTAssertEqual(decoded.optional, 1234567890)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testDecoding_WhenOptionalMissing() {
        do {
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
            XCTAssertEqual(decoded.required, 1234567890)
            XCTAssertNil(decoded.optional)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testDecoding_WhenRequiredMissing() {
        do {
            // Given
            let jsonObject: [String: Any?] = [
                "required": nil,
                "optional": "1234567890"
            ]

            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            
            // When
            let decoder = JSONDecoder()
            let _ = try decoder.decode(TestModel.self, from: data)
            
            // Then Fail
            XCTFail("Should have failed")
        } catch let decodingError as DecodingError {
            // Then Success
            switch decodingError {
            case .valueNotFound:
                break
            default:
                // Invalid error type
                XCTFail(decodingError.localizedDescription)
            }
        } catch {
            // Invalid error type
            XCTFail(error.localizedDescription)
        }
    }
    
    func testDecoding_WhenAllMissing() {
        do {
            // Given
            let jsonObject: [String: Any?] = [
                "required": nil,
                "optional": nil
            ]

            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            
            // When
            let decoder = JSONDecoder()
            let _ = try decoder.decode(TestModel.self, from: data)
            
            // Then Fail
            XCTFail("Should have failed")
        } catch let decodingError as DecodingError {
            // Then Success
            switch decodingError {
            case .valueNotFound:
                break
            default:
                // Invalid error type
                XCTFail(decodingError.localizedDescription)
            }
        } catch {
            // Invalid error type
            XCTFail(error.localizedDescription)
        }
    }
    
    func testDecoding_WhenNoKeys() {
        do {
            // Given
            let jsonObject: [String: Any?] = [:]
            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            
            // When
            let decoder = JSONDecoder()
            let _ = try decoder.decode(TestModel.self, from: data)
            
            // Then Fail
            XCTFail("Should have failed")
        } catch let decodingError as DecodingError {
            // Then Success
            switch decodingError {
            case .keyNotFound:
                break
            default:
                // Invalid error type
                XCTFail(decodingError.localizedDescription)
            }
        } catch {
            // Invalid error type
            XCTFail(error.localizedDescription)
        }
    }
}
