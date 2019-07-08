//
//  MockServerProvider.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-07-07.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import PiuPiu

class MockServerProvider: ServerProvider {
    var baseURL: URL? {
        return URL(string: "https://jsonplaceholder.typicode.com")
    }
    
    init() {}
}
