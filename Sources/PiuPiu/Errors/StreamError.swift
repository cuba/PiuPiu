//
//  StreamError.swift
//  PiuPiu
//
//  Created by Jacob Sikorski on 2025-03-21.
//

import Foundation

public enum StreamDataError: Error {
  case missingEventPrefix
  case missingDataPrefix
  case invalidEntry
  case missingStreamData
  case invalidFormat(String)
}
