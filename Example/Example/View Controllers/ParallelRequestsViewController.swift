//
//  ParallelRequestsViewController.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-07-04.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import UIKit
import PiuPiu

class ParallelRequestsViewController: UIViewController {
    lazy var sendButton: UIButton = {
        let button = UIButton()
        button.setTitle("Send", for: .normal)
        button.addTarget(self, action: #selector(tappedSendButton), for: .touchUpInside)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        return button
    }()
    
    lazy var textView: UITextView = {
        return UITextView()
    }()
    
    lazy var progressView: UIProgressView = {
        let progressView = UIProgressView()
        return progressView
    }()
    
    private let sampleCount = 100
    private let dispatcher = URLRequestDispatcher()
    private var pendingTasks: Set<URLSessionTask> = []
    
    deinit {
        dispatcher.invalidateAndCancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.groupedBackground
        title = "Parallel"
        setupLayout()
    }
    
    @objc private func tappedSendButton() {
        progressView.progress = 0
        
        ResponseFuture<[String]>
            .init {
                (1...sampleCount).map { id in
                    self.fetchUser(forId: id)
                }
            }
            .updated { [weak self] task in
                guard let self = self else { return }
                guard task.state == .completed || task.state == .running else {
                    self.pendingTasks.remove(task)
                    return
                }
                
                self.pendingTasks.insert(task)
                let completedTasks = self.pendingTasks.completed
                let progress = Float(completedTasks.count) / Float(self.sampleCount)
                print("PROGRESS: \(progress)")
                self.progressView.progress = progress
                
            }
            .response { [weak self] values in
                self?.textView.text = values.joined(separator: "\n\n")
            }
            .error { [weak self] error in
                self?.textView.text = error.localizedDescription
            }
            .completion { [weak self] in
                self?.progressView.progress = 1
                self?.pendingTasks = []
            }
            .send()
    }
    
    private func fetchUser(forId id: Int) -> ResponseFuture<String> {
        return dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!
            return URLRequest(url: url, method: .get)
        }).map(String.self) { response in
            return try response.decodeString(encoding: .utf8)
        }
    }
    
    private func setupLayout() {
        view.addSubview(sendButton)
        view.addSubview(progressView)
        view.addSubview(textView)
        
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        sendButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 15).isActive = true
        sendButton.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor).isActive = true
        sendButton.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor).isActive = true
        
        progressView.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 15).isActive = true
        progressView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor).isActive = true
        
        textView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 15).isActive = true
        textView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor).isActive = true
        textView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor).isActive = true
        textView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -20).isActive = true
    }
}
