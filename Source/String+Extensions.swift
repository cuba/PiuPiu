//
//  String+Extensions.swift
//  SafetyBoot
//
//  Created by Jacob Sikorski on 2017-03-20.
//  Copyright © 2017 Tamarai. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.networkKit, value: "", comment: "")
    }
}
