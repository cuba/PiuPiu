//
//  Cell.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-06-30.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import UIKit

enum Cell {
  case standard
  case subtitle
  case rightValue
  
  public var reuseIdentifier: String {
    switch self {
    case .standard:     return "StandardCell"
    case .subtitle:     return "SubtitleCell"
    case .rightValue:   return "RightValue"
    }
  }
  
  public var cellType: UITableViewCell.Type {
    switch self {
    default: return UITableViewCell.self
    }
  }
  
  @MainActor public func dequeueCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
    switch self {
    case .subtitle:
      return tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: reuseIdentifier)
    case .rightValue:
      return tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: reuseIdentifier)
    default:
      if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) {
        return cell
      } else {
        tableView.register(cellType, forCellReuseIdentifier: reuseIdentifier)
        return tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
      }
    }
  }
}
