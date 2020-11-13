//
//  CodingKey+Extensions.swift
//  
//
//  Created by Jakub Sikorski on 2020-10-16.
//

import Foundation

extension Array where Element == CodingKey {
    func appending(_ key: CodingKey) -> [CodingKey] {
        var codingPath = self
        codingPath.append(key)
        return codingPath
    }
}
