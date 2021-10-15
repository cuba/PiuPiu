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
        self.measure {
            let expectation = self.expectation(description: "Success response triggered")
            var future = ResponseFuture<[Post]>(result: [])
            
            for id in 1...50 {
                future = future.addingSeriesResult() { _ in
                    self.makePostFuture(id: id)
                }
            }
            
            future
                .success { posts in
                    expectation.fulfill()
                }
                .send()
            
            waitForExpectations(timeout: 10, handler: nil)
        }
    }
    
    func testParallelPerformance() {
        self.measure {
            let expectation = self.expectation(description: "Success response triggered")
            
            ResponseFuture<[Post]>
                .init {
                    (1...500).map { id in
                        makePostFuture(id: id)
                    }
                }
                .success { posts in
                    expectation.fulfill()
                }
                .send()
            
            waitForExpectations(timeout: 10, handler: nil)
        }
    }
    
    private func makePostFuture(id: Int) -> ResponseFuture<Post> {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!
        let urlRequest = URLRequest(url: url, method: .get)
        
        return self.dispatcher.dataFuture(from: urlRequest)
            .then { response in
                return try response.decode(Post.self)
            }
    }
}
