//
//  TestEncoding.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-04-13.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import Example
@testable import PiuPiu

class EncodingTests: XCTestCase {

    func testAddDataToRequest() {
        // Given
        let myData = Data(count: 0)
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        var request = URLRequest(url: url)
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
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        var request = URLRequest(url: url)
        request.setHTTPBody(string: jsonString, encoding: .utf8)
        XCTAssertNotNil(request.httpBody)
    }
    
    func testEncodeJsonObject() {
        let jsonObject: [String: Any?] = [
            "id": "123",
            "name": "Kevin Malone"
        ]
        
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        var request = URLRequest(url: url)
        XCTAssertNoThrow(try request.setJSONBody(jsonObject: jsonObject))
        XCTAssertNotNil(request.httpBody)
    }
    
    func testEncodeEncodable() {
        let myCodable = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        var request = URLRequest(url: url)
        XCTAssertNoThrow(try request.setJSONBody(encodable: myCodable))
        XCTAssertNotNil(request.httpBody)
    }
}
