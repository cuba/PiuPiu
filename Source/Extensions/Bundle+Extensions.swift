//
//  Bundle+Extensions.swift
//  SafetyBoot
//
//  Created by Jacob Sikorski on 2017-03-20.
//  Copyright © 2017 Tamarai. All rights reserved.
//

import Foundation

public extension Bundle {
    
    /// Access to the `PewPew` Bundle
    static var networkKit: Bundle {
        return Bundle(identifier: "com.jacobsikorski.PewPew")!
    }
}
