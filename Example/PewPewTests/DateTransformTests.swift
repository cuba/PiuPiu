//
//  DateTransformTests.swift
//  PewPewTests
//
//  Created by Jacob Sikorski on 2019-11-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import XCTest
import PiuPiu

class DateTransformTests: XCTestCase {
    /// A formatter using the following format: `yyyy-MM-dd'T'HH:mm:ssZZZZZ`
    private let formatter: DateFormatter = {
        let rfc3339DateFormatter = DateFormatter()
        rfc3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        rfc3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        rfc3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return rfc3339DateFormatter
    }()
    
    func testFromJSONTransform() {
        // Given
        let transform = DateTransform(formatter: formatter, codingPath: [])
        let timeZone = TimeZone(identifier: "America/Montreal")!
        let components = DateComponents(calendar: .current, timeZone: timeZone, year: 2019, month: 03, day: 10, hour: 9, minute: 10, second: 11)
        let testDate = components.date!
        
        do {
            // When
            let date = try transform.from(json: "2019-03-10T13:10:11Z", codingPath: [])
            XCTAssertEqual(date, testDate)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testToJSONTransform() {
        // Given
        let transform = DateTransform(formatter: formatter, codingPath: [])
        let timeZone = TimeZone(identifier: "America/Montreal")!
        let components = DateComponents(calendar: .current, timeZone: timeZone, year: 2019, month: 03, day: 10, hour: 9, minute: 10, second: 11)
        let date = components.date!
        
        do {
            // When
            let value = try transform.toJSON(date, codingPath: [])
            XCTAssertEqual(value, "2019-03-10T13:10:11Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
