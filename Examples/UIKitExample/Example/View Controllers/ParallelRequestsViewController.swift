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
  
  // Always hold a strong reference to the dispatcher
  private let dispatcher = URLRequestDispatcher(
    session: URLSession(
      configuration: URLSessionConfiguration.ephemeral
    )
  )
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.systemGroupedBackground
    title = "Parallel"
    setupLayout()
  }
  
  @objc private func tappedSendButton() {
    progressView.progress = 0
    var results: [String?] = Array(repeating: nil, count: sampleCount)
    let progressIncrement = 1.0 / Float(sampleCount)
    
    Task {
      do {
        // For parallel requests, put each request in its own Task
        // But you will have to manage order yourself.
        try await (1...sampleCount).enumerated().parallelForEach { index, id in
          let result = try await self.fetchPost(forId: id)
          
          Task { @MainActor in
            results[index] = result.body
            let availableResults = results.compactMap(\.self)
            self.progressView.progress = Float(availableResults.count) * progressIncrement
            self.textView.text = availableResults.joined(separator: ",\n")
          }
        }
      } catch {
        textView.text = error.localizedDescription
        progressView.progress = 0
      }
    }
  }
  
  private func fetchPost(forId id: Int) async throws -> HTTPResponse<String> {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!
    let request = URLRequest(url: url, method: .get)
    return try await dispatcher.data(from: request)
      .log()
      .ensureHTTPResponse()
      .ensureBody()
      .ensureStringBody()
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
