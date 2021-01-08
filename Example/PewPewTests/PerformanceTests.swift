//
//  PerformanceTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-07-12.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import PiuPiu
@testable import Example

class PerformanceTests: XCTestCase {
    private let dispatcher = MockURLRequestDispatcher(delay: 0, callback: { request in
        if let id = request.integerValue(atIndex: 1, matching: [.constant("posts"), .wildcard(type: .integer)]) {
            let post = Post(id: id, userId: 123, title: "Some post", body: "Lorem ipsum ...")
            return try Response.makeMockJSONResponse(with: request, encodable: post, statusCode: .ok)
        } else if request.pathMatches(pattern: [.constant("posts")]) {
            let post = Post(id: 123, userId: 123, title: "Some post", body: "Lorem ipsum ...")
            return try Response.makeMockJSONResponse(with: request, encodable: [post], statusCode: .ok)
        } else {
            return Response.makeMockResponse(with: request, statusCode: .notFound)
        }
    })
    
    func testSeriesPerformance() {
        let expectation = self.expectation(description: "Success response triggered")
        var future = ResponseFuture<[Post]>(result: [])
        
        for id in 1...500 {
            future = future.addingSeriesResult() { _ in
                let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!
                let request = URLRequest(url: url, method: .get)
                
                return self.dispatcher.dataFuture(from: request).map(Post.self) { response in
                    return try response.decode(Post.self)
                }
            }
        }
        
        self.measure {
            future.response({ posts in
                expectation.fulfill()
            }).send()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testParallelPerformance() {
        let expectation = self.expectation(description: "Success response triggered")
        
        var future = ResponseFuture<[Post]>(result: [])
        
        for id in 1...500 {
            future = future.addingParallelResult() {
                let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!
                let request = URLRequest(url: url, method: .get)
                
                return self.dispatcher.dataFuture(from: request).map(Post.self) { response in
                    return try response.decode(Post.self)
                }
            }
        }
        
        self.measure {
            future.response({ posts in
                expectation.fulfill()
            }).send()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }

}
