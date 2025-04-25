//
//  String+Extensions.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-04-19.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

extension String {
  func localized(bundle: Bundle = Bundle.main) -> String {
    return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
  }
}
