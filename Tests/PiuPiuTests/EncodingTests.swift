//
//  EncodingTests.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-04-21.
//

import Testing
import Foundation
import PiuPiu

struct EncodingTests {
  @Test func addDataToRequest() {
    // Given
    let myData = Data(count: 0)
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
    var request = URLRequest(url: url)
    request.httpBody = myData
    #expect(request.httpBody != nil)
  }
  
  @Test func encodeJsonString() {
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
    #expect(request.httpBody != nil)
  }
  
  @Test func encodeJsonObject() throws {
    let jsonObject: [String: Any?] = [
      "id": "123",
      "name": "Kevin Malone"
    ]
    
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
    var request = URLRequest(url: url)
    try request.setJSONBody(jsonObject: jsonObject)
    #expect(request.httpBody != nil)
  }
  
  @Test func encodeEncodable() throws {
    let myCodable = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
    var request = URLRequest(url: url)
    try request.setJSONBody(encodable: myCodable)
    #expect(request.httpBody != nil)
  }
}
