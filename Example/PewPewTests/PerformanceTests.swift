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
    private lazy var dispatcher: URLRequestDispatcher = {
        return URLRequestDispatcher(responseAdapter: MockHTTPResponseAdapter.success)
    }()
    
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
                    (1...50).map { id in
                        makePostFuture(id: id)
                    }
                }
                .success { posts in
                    expectation.fulfill()
                }
                .send()
            
            waitForExpectations(timeout: 20, handler: nil)
        }
    }
    
    private func makePostFuture(id: Int) -> ResponseFuture<Post> {
        let url = MockJSON.post.url
        let urlRequest = URLRequest(url: url, method: .get)
        
        return self.dispatcher.dataFuture(from: urlRequest)
            .then { response in
                return try response.decode(Post.self)
            }
    }
}
