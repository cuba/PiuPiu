//
//  TestEncoding.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-04-13.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import Example
@testable import PewPew

class EncodingTests: XCTestCase {

    func testAddDataToRequest() {
        // Given
        let myData = Data(count: 0)
        
        var request = BasicRequest(method: .post, path: "/users")
        request.httpBody = myData
        XCTAssertNotNil(request.httpBody)
    }
    
    func testEncodeJsonString() {
        // Given
        let jsonString = """
            {
                "name": "Jim Halpert"
            }
        """
        
        // Example
        var request = BasicRequest(method: .post, path: "/users")
        request.setHTTPBody(string: jsonString, encoding: .utf8)
        XCTAssertNotNil(request.httpBody)
    }
    
    func testEncodeJsonObject() {
        do {
            let jsonObject: [String: Any?] = [
                "id": "123",
                "name": "Kevin Malone"
            ]
            
            var request = BasicRequest(method: .post, path: "/users")
            try request.setJSONBody(jsonObject: jsonObject)
            XCTAssertNotNil(request.httpBody)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testEncodeEncodable() {
        let myCodable = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        
        do {
            var request = BasicRequest(method: .post, path: "/posts")
            try request.setJSONBody(encodable: myCodable)
            XCTAssertNotNil(request.httpBody)
        } catch {
            XCTFail("Should not throw")
        }
    }
    
    func testEncodeMapEncodable() {
        let mappable = MapCodablePost(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        var request = BasicRequest(method: .post, path: "/posts")
        
        do {
            try request.setJSONBody(mapEncodable: mappable)
            XCTAssertNotNil(request.httpBody)
        } catch {
            XCTFail("Should not throw")
        }
    }

}
