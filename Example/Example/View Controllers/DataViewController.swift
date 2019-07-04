//
//  DataViewController.swift
//  Example
//
//  Created by Jacob Sikorski on 2017-05-22.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import UIKit
import PiuPiu

class DataViewController: UIViewController {
    lazy var sendButton: UIButton = {
        let button = UIButton()
        button.setTitle("Send", for: .normal)
        button.addTarget(self, action: #selector(tappedSendButton), for: .touchUpInside)
        button.setTitleColor(UIColor.blue, for: .normal)
        button.tintColor = UIColor.black
        return button
    }()
    
    lazy var textView: UITextView = {
        return UITextView()
    }()
    
    lazy var progressView: UIProgressView = {
        let progressView = UIProgressView()
        return progressView
    }()
    
    private let dispatcher = URLRequestDispatcher()
    
    deinit {
        print("DEINIT")
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.groupTableViewBackground
        title = "JSON"
        setupLayout()
    }
    
    @objc private func tappedSendButton() {
        progressView.progress = 0
        
        var future = ResponseFuture<[String]>(result: [])
        
        // Make more requests
        for id in 1...10 {
            future = future.replace({ values -> ResponseFuture<[String]> in
                return self.fetchPost(forId: id).then({ value -> [String] in
                    var values = values
                    values.append(value)
                    return values
                })
            })
        }
        
        future.progress({ [weak self] progress in
            print("PROGRESS: \(progress)")
            self?.progressView.progress = Float(progress)
        }).response({ [weak self] values in
            self?.textView.text = values.joined(separator: "\n\n")
        }).error({ [weak self] error in
            self?.textView.text = error.localizedDescription
        }).send()
    }
    
    private func fetchPost(forId id: Int) -> ResponseFuture<String> {
        return dispatcher.dataFuture(from: {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!
            return try URLRequest(url: url, method: .get)
        }).then({ response -> String in
            return try response.decodeString(encoding: .utf8)
        })
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
