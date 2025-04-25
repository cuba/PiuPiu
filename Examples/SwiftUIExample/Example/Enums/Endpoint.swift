//
//  Endpoint.swift
//  Example
//
//  Created by Jacob Sikorski on 2025-04-22.
//

import Foundation
import PiuPiu

enum Endpoint: URLEndpoint {
  case posts
  case post(id: Int)
  
  var path: [PathValue] {
    switch self {
    case .posts:
      return [.string("posts")]
    case .post(let id):
      return [.string("posts"), .integer(id)]
    }
  }
}

public protocol URLEndpoint {
  var path: [PathValue] { get }
}

public extension URLEndpoint {
  var pathString: String {
    return path.string
  }
}
