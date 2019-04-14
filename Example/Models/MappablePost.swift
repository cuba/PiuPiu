//
//  MappablePost.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-04-13.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import ObjectMapper

struct MappablePost: ImmutableMappable {
    let id: Int?
    let userId: Int
    let title: String
    let body: String

    init(id: Int?, userId: Int, title: String, body: String) {
        self.id = id
        self.userId = userId
        self.title = title
        self.body = body
    }

    init(map: Map) throws {
        self.id = try map.value("id")
        self.userId = try map.value("userId")
        self.title = try map.value("title")
        self.body = try map.value("body")
    }

    func mapping(map: Map) {
        id      >>> map["id"]
        userId  >>> map["userId"]
        title   >>> map["title"]
        body    >>> map["body"]
    }
}
