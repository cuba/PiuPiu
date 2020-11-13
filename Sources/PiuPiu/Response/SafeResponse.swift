//
//  SafeResponse.swift
//  PiuPiu
//
//  Created by Jakub Sikorski on 2020-07-25.
//  Copyright © 2020 Jacob Sikorski. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Use Apple's `Result<Success, Failure>` object")
public enum SafeResponse<T> {
    case response(T)
    case error(Error)
}
