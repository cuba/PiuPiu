//
//  StatusCodeTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2021-10-14.
//  Copyright © 2021 Jacob Sikorski. All rights reserved.
//

import Testing
import PiuPiu
import Foundation

@Test func localizableError() async throws {
  let statusCode = StatusCode.badRequest
  let localized = HTTPURLResponse.localizedString(forStatusCode: statusCode.rawValue)
  #expect(statusCode.localizedDescription == localized)
}

@Test func httpError() async throws {
  let statusCode = StatusCode.badRequest
  #expect(statusCode.httpError == .clientError(statusCode))
}
