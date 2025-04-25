//
//  Logger+Extensions.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-03-21.
//

import os.log

extension Logger {
  static let network = Logger(
    subsystem: "com.jacobsikorski.piupiu", category: "Network"
  )
  static let stream = Logger(
    subsystem: "com.jacobsikorski.piupiu", category: "Stream"
  )
}
