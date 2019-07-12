//
//  URLExtensionTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-07-12.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
@testable import PiuPiu

class URLExtensionTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPathValues_WithInteger() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/14321431134124")!
        let values = url.pathValues(from: [.constant("posts"), .wildcard(type: .integer)])
        
        XCTAssertNotNil(values)
        XCTAssertEqual(values?.count, 2)
        XCTAssertEqual(values?.first, PathValue.string("posts"))
        XCTAssertEqual(values?.last, PathValue.integer(14321431134124))
    }
    
    func testPathValues_WithString() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/14321431134124")!
        let values = url.pathValues(from: [.constant("posts"), .wildcard(type: .string)])
        
        XCTAssertNotNil(values)
        XCTAssertEqual(values?.count, 2)
        XCTAssertEqual(values?.first, PathValue.string("posts"))
        XCTAssertEqual(values?.last, PathValue.string("14321431134124"))
    }
    
    func testPathValues_WithExtraSlash() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts//14321431134124")!
        let values = url.pathValues(from: [.constant("posts"), .wildcard(type: .integer)])
        
        XCTAssertNotNil(values)
        XCTAssertEqual(values?.count, 2)
        XCTAssertEqual(values?.first, PathValue.string("posts"))
        XCTAssertEqual(values?.last, PathValue.integer(14321431134124))
    }
    
    func testPathValues_WithQueryParams() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/14321431134124?test=value")!
        let values = url.pathValues(from: [.constant("posts"), .wildcard(type: .integer)])
        
        XCTAssertNotNil(values)
        XCTAssertEqual(values?.count, 2)
        XCTAssertEqual(values?.first, PathValue.string("posts"))
        XCTAssertEqual(values?.last, PathValue.integer(14321431134124))
    }
    
    func testPathValues_WithoutDomainWithoutPrefixedSlash() {
        let url = URL(string: "posts/14321431134124")!
        let values = url.pathValues(from: [.constant("posts"), .wildcard(type: .integer)])
        
        XCTAssertNotNil(values)
        XCTAssertEqual(values?.count, 2)
        XCTAssertEqual(values?.first, PathValue.string("posts"))
        XCTAssertEqual(values?.last, PathValue.integer(14321431134124))
    }
    
    func testPathValues_WithoutDomainWithPrefixedSlash() {
        let url = URL(string: "/posts/14321431134124")!
        let values = url.pathValues(from: [.constant("posts"), .wildcard(type: .integer)])
        
        XCTAssertNotNil(values)
        XCTAssertEqual(values?.count, 2)
        XCTAssertEqual(values?.first, PathValue.string("posts"))
        XCTAssertEqual(values?.last, PathValue.integer(14321431134124))
    }
}
