//
//  ServerProvider.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Foundation

public protocol ServerProvider {
    var baseURL: URL { get }
}
