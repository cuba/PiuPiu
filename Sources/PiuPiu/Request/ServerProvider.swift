//
//  ServerProvider.swift
//  SwiftTrader
//
//  Created by Jacob Sikorski on 2017-05-17.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//
import Foundation

/// The object that returns the server host or base url
public protocol ServerProvider: AnyObject {
    /// The base url that will be used to construct
    var baseURL: URL? { get }
}
