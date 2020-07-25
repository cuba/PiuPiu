//
//  UIColor+Extensions.swift
//  Example
//
//  Created by Jakub Sikorski on 2020-07-25.
//  Copyright © 2020 Jacob Sikorski. All rights reserved.
//

import UIKit

extension UIColor {
    static var groupedBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.systemGroupedBackground
        } else {
            return UIColor.groupTableViewBackground
        }
    }
}
