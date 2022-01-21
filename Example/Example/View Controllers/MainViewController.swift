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
        case seriesExample
        case parallelExample
        case downloadExample
        case uploadExample
        case asyncAwait
    }
    
    lazy var tableView: UITableView = {
        if #available(iOS 13.0, *) {
            return UITableView(frame: CGRect.zero, style: .insetGrouped)
        } else {
            return UITableView(frame: CGRect.zero, style: .grouped)
        }
    }()
    
    private var rows: [Row] = [.seriesExample, .parallelExample, .downloadExample, .uploadExample, .asyncAwait]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "PiuPiu"

        // Setup table view
        tableView.delegate = self
        tableView.dataSource = self
        
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
        case .seriesExample:
            let cell = Cell.subtitle.dequeueCell(for: tableView, at: indexPath)
            cell.textLabel?.text = "Series example"
            cell.detailTextLabel?.text = "Perform sample api calls in series"
            cell.imageView?.image = makeImage(systemName: "square.and.arrow.down")
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .parallelExample:
            let cell = Cell.subtitle.dequeueCell(for: tableView, at: indexPath)
            cell.textLabel?.text = "Parallel example"
            cell.detailTextLabel?.text = "Perform sample api calls in parallel"
            cell.imageView?.image = makeImage(systemName: "square.and.arrow.down.on.square")
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .downloadExample:
            let cell = Cell.subtitle.dequeueCell(for: tableView, at: indexPath)
            cell.textLabel?.text = "Download example"
            cell.detailTextLabel?.text = "Perform a sample image download API call"
            cell.imageView?.image = makeImage(systemName: "photo")
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .uploadExample:
            let cell = Cell.subtitle.dequeueCell(for: tableView, at: indexPath)
            cell.textLabel?.text = "Upload example"
            cell.detailTextLabel?.text = "Perform a sample upload API call"
            cell.imageView?.image = makeImage(systemName: "paperclip")
            cell.accessoryType = .disclosureIndicator
            return cell

        case .asyncAwait:
            let cell = Cell.subtitle.dequeueCell(for: tableView, at: indexPath)
            cell.textLabel?.text = "Async/Await Example"

            if #available(iOS 13.0.0, *) {
                cell.detailTextLabel?.text = "Example of an async await API call"
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.detailTextLabel?.text = "Example of an async await API call (Only available on iOS 13 +)"
                cell.textLabel?.textColor = .lightGray
                cell.detailTextLabel?.textColor = .lightGray
                cell.accessoryType = .none
            }

            cell.detailTextLabel?.text = "Example of an async await API call"
            cell.imageView?.image = makeImage(systemName: "hourglass")
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch row {
        case .seriesExample:
            let viewController = SeriesRequestsViewController()
            navigationController?.pushViewController(viewController, animated: true)
        case .parallelExample:
            let viewController = ParallelRequestsViewController()
            navigationController?.pushViewController(viewController, animated: true)
        case .downloadExample:
            let viewController = DownloadViewController()
            navigationController?.pushViewController(viewController, animated: true)
        case .uploadExample:
            let viewController = UploadViewController()
            navigationController?.pushViewController(viewController, animated: true)
        case .asyncAwait:
            if #available(iOS 13.0.0, *) {
                let viewController = AsyncAwaitViewController()
                navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }
    
    private func makeImage(systemName: String) -> UIImage? {
        if #available(iOS 13.0, *) {
            return UIImage(systemName: systemName)
        } else {
            return nil
        }
    }
}
