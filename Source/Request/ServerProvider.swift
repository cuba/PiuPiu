//
//  ServerProvider.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//
import Foundation

/// The object that returns the server host or base url
public protocol ServerProvider: class {
    var baseURL: URL? { get }
}
