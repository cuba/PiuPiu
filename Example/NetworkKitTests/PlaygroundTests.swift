//
//  PlaygroundTests.swift
//  NetworkKitTests
//
//  Created by Jacob Sikorski on 2019-04-13.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import NetworkKit

class PlaygroundTests: XCTestCase, ServerProvider {
    
    struct Country: Decodable {
    }
    
    class PrintfulResult<T: Decodable>: Decodable {
        var code: StatusCode
        var result: T
    }
    
    var baseURL: URL {
        return URL(string: "https://jsonplaceholder.typicode.com")!
    }
    
    func testAnnasExample() {
        getCountries().response({ countries in
            // Handle your success
        }).error({ error in
            // Handle your failure
        }).completion({
            // Handle your completion
        }).send()
    }

    func getCountries() -> ResponseFuture<[Country]> {
        let endpoint = "/posts"
        let dispatcher = NetworkDispatcher(serverProvider: self)
        let request = BasicRequest(method: .get, path: endpoint)
        
        return dispatcher.future(from: request).then({ response -> [Country] in
            let printfulResult = try response.decode(PrintfulResult<[Country]>.self)
            
            if let error = printfulResult.code.makeError(cause: nil) {
                throw error
            } else {
                return printfulResult.result
            }
        })
    }
}
