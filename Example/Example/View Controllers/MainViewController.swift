//
//  MainViewController.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-06-30.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    enum Row {
        case jsonExample
        case downloadExample
    }
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    private var rows: [Row] = [.jsonExample, .downloadExample]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "PiuPiu"
        
        setupLayout()
    }
    
    private func setupLayout() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        
        switch row {
        case .jsonExample:
            let cell = Cell.standard.dequeCell(for: tableView, at: indexPath)
            cell.textLabel?.text = "JSON Example"
            return cell
        case .downloadExample:
            let cell = Cell.standard.dequeCell(for: tableView, at: indexPath)
            cell.textLabel?.text = "Download Example"
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        
        switch row {
        case .jsonExample:
            let viewController = DataViewController()
            navigationController?.pushViewController(viewController, animated: true)
        case .downloadExample:
            let viewController = DownloadViewController()
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
