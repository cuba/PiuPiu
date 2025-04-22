//
//  CloudinaryError.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-07-04.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import PiuPiu

public enum CloudinaryError: Error {
  case uploadFailed(reason: String?, cause: ResponseError)
}

extension CloudinaryError: LocalizedError {
  public var localizedDescription: String {
    switch self {
    case .uploadFailed(let reason, let cause):
      return reason ?? cause.localizedDescription
    }
  }
}
