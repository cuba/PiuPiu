//
//  Logger+Extensions.swift
//  Example
//
//  Created by Jacob Sikorski on 2025-04-23.
//

import os.log

extension Logger {
  static let uploads = Logger(
    subsystem: "com.jacobsikorski.piupiu.Example",
    category: "Uploads"
  )
}
