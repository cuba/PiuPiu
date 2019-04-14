//
//  MapCodablePost.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-04-13.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import MapCodableKit

struct MapCodablePost: MapCodable {
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
        id = try map.value(from: "id")
        userId = try map.value(from: "userId")
        title = try map.value(from: "title")
        body = try map.value(from: "body")
    }
    
    func fill(map: Map) throws {
        try map.add(id, for: "id")
        try map.add(userId, for: "userId")
        try map.add(title, for: "title")
        try map.add(body, for: "body")
    }
}
