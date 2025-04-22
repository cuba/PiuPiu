//
//  MockJSON.swift
//  PewPewTests
//
//  Created by Jakub Sikorski on 2022-01-19.
//  Copyright © 2022 Jacob Sikorski. All rights reserved.
//

import Foundation

enum MockJSON {
  case post
  case posts
  case user
  
  fileprivate var resource: String {
    switch self {
    case .post: return "post"
    case .posts: return "posts"
    case .user: return "user"
    }
  }
  
  var url: URL {
    return MockJSONLoader.url(for: self)
  }
}

private class MockJSONLoader {
  static func url(for json: MockJSON) -> URL {
    return Bundle(for: Self.self).url(forResource: json.resource, withExtension: "json")!
  }
}
