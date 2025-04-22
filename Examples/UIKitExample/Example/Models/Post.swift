//
//  Post.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-04-13.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

struct Post: Codable {
  let id: Int
  let userId: Int
  let title: String
  let body: String
}
