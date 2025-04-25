//
//  URLExtensionTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-07-12.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Testing
import Foundation
import PiuPiu

struct URLExtensionTests {
  @Test func withInteger() {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/14321431134124")!
    let values = url.pathValues(matching: [.constant("posts"), .wildcard(type: .integer)])
    
    #expect(values != nil)
    #expect(values?.count == 2)
    #expect(values?.first == PathValue.string("posts"))
    #expect(values?.last == PathValue.integer(14321431134124))
  }
  
  @Test func withString() {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/14321431134124")!
    let values = url.pathValues(matching: [.constant("posts"), .wildcard(type: .string)])
    
    #expect(values != nil)
    #expect(values?.count == 2)
    #expect(values?.first == PathValue.string("posts"))
    #expect(values?.last == PathValue.string("14321431134124"))
  }
  
  @Test func withExtraSlash() {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts//14321431134124")!
    let values = url.pathValues(matching: [.constant("posts"), .wildcard(type: .integer)])
    
    #expect(values != nil)
    #expect(values?.count == 2)
    #expect(values?.first == PathValue.string("posts"))
    #expect(values?.last == PathValue.integer(14321431134124))
  }
  
  @Test func withQueryParams() {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/14321431134124?test=value")!
    let values = url.pathValues(matching: [.constant("posts"), .wildcard(type: .integer)])
    
    #expect(values != nil)
    #expect(values?.count == 2)
    #expect(values?.first == PathValue.string("posts"))
    #expect(values?.last == PathValue.integer(14321431134124))
  }
  
  @Test func withoutDomainWithoutPrefixedSlash() {
    let url = URL(string: "posts/14321431134124")!
    let values = url.pathValues(matching: [.constant("posts"), .wildcard(type: .integer)])
    
    #expect(values != nil)
    #expect(values?.count == 2)
    #expect(values?.first == PathValue.string("posts"))
    #expect(values?.last == PathValue.integer(14321431134124))
  }
  
  @Test func withoutDomainWithPrefixedSlash() {
    let url = URL(string: "/posts/14321431134124")!
    let values = url.pathValues(matching: [.constant("posts"), .wildcard(type: .integer)])
    
    #expect(values != nil)
    #expect(values?.count == 2)
    #expect(values?.first == PathValue.string("posts"))
    #expect(values?.last == PathValue.integer(14321431134124))
  }
}
