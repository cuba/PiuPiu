//
//  AsyncAwaitViewController.swift
//  Example
//
//  Created by Jakub Sikorski on 2022-01-20.
//  Copyright © 2022 Jacob Sikorski. All rights reserved.
//

import UIKit
import PiuPiu

@available(iOS 13.0.0, *)
class AsyncAwaitViewController: UIViewController {
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

    private let dispatcher = URLRequestDispatcher()
    private var pendingTasks: Set<URLSessionTask> = []

    deinit {
        dispatcher.invalidateAndCancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.groupedBackground
        title = "Async/Await"
        setupLayout()
    }

    @objc private func tappedSendButton() {
        progressView.progress = 0

        Task {
            do {
                let response = try await fetchData()
                textView.text = response.data
            } catch {
                textView.text = error.localizedDescription
            }
        }
    }

    private func fetchData() async throws -> Response<String> {
        return try await fetchUser(forId: 1)
            .updated { [weak self] task in
                self?.progressView.progress = task.percentTransferred ?? 0
            }
            .fetchResult()
    }

    private func fetchUser(forId id: Int) -> ResponseFuture<Response<String>> {
        let url = URL(string: "https://jsonplaceholder.typicode.com/users/\(id)")!
        let urlRequest = URLRequest(url: url, method: .get)

        return dispatcher.dataFuture(from: urlRequest)
            .then { response in
                #if DEBUG
                response.debug()
                #endif

                return response
            }
            .decodedString()
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

@available(iOS 13.0.0, *)
extension AsyncAwaitViewController: URLResponseAdapter {
    func adapt(urlResponse: URLResponse, for urlRequest: URLRequest, with callback: @escaping (URLResponse) throws -> Void) throws {
        try callback(urlResponse)
    }
}
