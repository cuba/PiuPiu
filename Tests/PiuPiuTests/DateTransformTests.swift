//
//  DateTransformTests.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-04-21.
//

import Testing
import Foundation
import PiuPiu

struct DateTransformTests {
  /// A formatter using the following format: `yyyy-MM-dd'T'HH:mm:ssZZZZZ`
  private let formatter: DateFormatter = {
    let rfc3339DateFormatter = DateFormatter()
    rfc3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
    rfc3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    rfc3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return rfc3339DateFormatter
  }()
  
  @Test func fromJSONTransform() throws {
    // Given
    let transform = DateTransform(formatter: formatter, codingPath: [])
    let timeZone = TimeZone(identifier: "America/Montreal")!
    let components = DateComponents(calendar: .current, timeZone: timeZone, year: 2019, month: 03, day: 10, hour: 9, minute: 10, second: 11)
    let testDate = components.date!
    let date = try transform.from(json: "2019-03-10T13:10:11Z", codingPath: [])
    #expect(date == testDate)
  }
  
  @Test func toJSONTransform() throws {
    // Given
    let transform = DateTransform(formatter: formatter, codingPath: [])
    let timeZone = TimeZone(identifier: "America/Montreal")!
    let components = DateComponents(calendar: .current, timeZone: timeZone, year: 2019, month: 03, day: 10, hour: 9, minute: 10, second: 11)
    let date = components.date!
    let value = try transform.toJSON(date, codingPath: [])
    
    #expect(value == "2019-03-10T13:10:11Z")
  }
}
