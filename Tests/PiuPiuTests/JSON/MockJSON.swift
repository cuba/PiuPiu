//
//  MockJSON.swift
//  PewPewTests
//
//  Created by Jakub Sikorski on 2022-01-19.
//  Copyright © 2022 Jacob Sikorski. All rights reserved.
//

import Foundation

enum MockJSON: String {
  case post
  case posts
  case user
  
  var url: URL {
    return Bundle.module.url(forResource: self.rawValue, withExtension: "json")!
  }
}
