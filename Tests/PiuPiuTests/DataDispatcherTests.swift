//
//  DataDispatcherTests.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-04-21.
//

import Testing
import Foundation
import PiuPiu

@MainActor struct DataDispatcherTests {
  let dispatcher = URLRequestDispatcher(
    responseAdapter: MockHTTPResponseAdapter.default
  )
  
  @Test func simpleRequest() async throws {
    let url = MockJSON.post.url
    let urlRequest = URLRequest(url: url, method: .get)
    
    let response = try await dispatcher.data(from: urlRequest)
      .ensureHTTPResponse()
      .ensureValidResponse()
      .ensureDecoded(Post.self)
    
    // Do something with response
    let post = response.body
    #expect(post.id == 1)
  }
  
  @Test func getPostsExample() async throws {
    let url = MockJSON.posts.url
    let urlRequest = URLRequest(url: url, method: .get)
    
    let response = try await dispatcher.data(from: urlRequest)
      .ensureHTTPResponse()
      .ensureValidResponse()
      .ensureDecoded([Post].self)
    
    // Do something with response
    let posts = response.body
    #expect(posts.count == 4)
  }
}
