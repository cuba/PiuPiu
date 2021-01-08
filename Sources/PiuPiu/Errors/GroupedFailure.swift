//
//  GroupedFailure.swift
//  
//
//  Created by Jacob Sikorski on 2021-01-07.
//

import Foundation

enum GroupedFailure: Error {
    case two(Error, Error)
}
