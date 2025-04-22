//
//  Test.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-04-21.
//

import Testing
import Foundation
import PiuPiu

@MainActor struct DecodingTests {
  let dispatcher = URLRequestDispatcher(
    responseAdapter: MockHTTPResponseAdapter.default
  )
  
  @Test func unwrappingData() async throws {
    let request = URLRequest(url: MockJSON.posts.url, method: .get)
    let response = try await dispatcher.data(from: request)
      .ensureBody()
    
    // Do something with response
    let data = response.body
    #expect(!data.isEmpty)
  }
  
  @Test func decodingString() async throws {
    let request = URLRequest(url: MockJSON.post.url, method: .get)
    let response = try await dispatcher.data(from: request)
      .ensureStringBody(encoding: .utf8)
    
    // Do something with response
    let stringBody = response.body
    #expect(!stringBody.isEmpty)
  }
  
  @Test func decodingDecodable() async throws {
    let request = URLRequest(url: MockJSON.posts.url, method: .get)
    let response = try await dispatcher.data(from: request)
      .ensureDecoded([Post].self)
    
    // Do something with response post
    let posts = response.body
    #expect(posts.count == 4)
  }
  
  @Test func unsuccessfulCodableDeserialization() async {
    let request = URLRequest(url: MockJSON.post.url, method: .get)
    
    await #expect(throws: Error.self, performing: {
      try await dispatcher.data(from: request)
        .ensureDecoded([Post].self)
    })
  }
}
