//
//  SeriesRequestsViewController.swift
//  Example
//
//  Created by Jacob Sikorski on 2017-05-22.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import UIKit
import PiuPiu

class SeriesRequestsViewController: UIViewController {
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
        title = "Series"
        setupLayout()
    }
    
    @objc private func tappedSendButton() {
        pendingTasks.forEach({ $0.cancel() })
        pendingTasks = []
        progressView.progress = 0
        
        var future = ResponseFuture<[Result<String, Error>]>(result: [])
        
        // Make more requests
        for id in 1...sampleCount {
            future = future.addingSeriesResult() { [weak self] values in
                return self?.fetchPost(forId: id)
            }
        }
        
        future.updated { [weak self] task in
            guard let self = self else { return }
            guard task.state == .completed || task.state == .running else {
                self.pendingTasks.remove(task)
                return
            }
            
            self.pendingTasks.insert(task)
            let progress = Float(self.pendingTasks.completed.count) / Float(self.sampleCount)
            print("PROGRESS: \(progress)")
            self.progressView.progress = progress
        }.response { [weak self] values in
            self?.textView.text = values.map({ result in
                switch result {
                case .success(let value):
                    return value
                case .failure(let error):
                    return error.localizedDescription
                }
            }).joined(separator: "\n\n")
        }.error { [weak self] error in
            self?.textView.text = error.localizedDescription
        }.send()
    }
    
    private func fetchPost(forId id: Int) -> ResponseFuture<Result<String, Error>> {
        return dispatcher.dataFuture {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!
            return URLRequest(url: url, method: .get)
        }.then { response -> String in
            return try response.decodeString(encoding: .utf8)
        }.safeResult()
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
