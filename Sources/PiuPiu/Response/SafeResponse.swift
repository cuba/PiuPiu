//
//  SafeResponse.swift
//  PiuPiu
//
//  Created by Jakub Sikorski on 2020-07-25.
//  Copyright © 2020 Jacob Sikorski. All rights reserved.
//

import Foundation

public enum SafeResponse<T> {
    case response(T)
    case error(Error)
}
