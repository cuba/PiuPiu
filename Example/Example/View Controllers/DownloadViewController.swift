//
//  DownloadViewController.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-06-30.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import UIKit
import PiuPiu

class DownloadViewController: BaseViewController {
    lazy var sendButton: UIButton = {
        let button = UIButton()
        button.setTitle("Send", for: .normal)
        button.addTarget(self, action: #selector(tappedSendButton), for: .touchUpInside)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        return button
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var fileUrlTextField: UITextField = {
        let textField = UITextField()
        textField.text = "https://davidlevine.files.wordpress.com/2010/01/butterflynova.jpg"
        textField.keyboardType = .URL
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.borderStyle = .roundedRect
        textField.placeholder = "File URL"
        return textField
    }()
    
    lazy var progressView: UIProgressView = {
        let progressView = UIProgressView()
        return progressView
    }()
    
    private var currentTextField: UITextField?
    private let dispatcher = URLRequestDispatcher()
    
    deinit {
        dispatcher.invalidateAndCancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.groupedBackground
        title = "Download"
        setupLayout()
        
        // Configure the Text Fields
        fileUrlTextField.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // dispatcher.invalidateAndCancel()
    }
    
    @objc private func tappedSendButton() {
        currentTextField?.resignFirstResponder()
        progressView.progress = 0
        
        guard let urlString = fileUrlTextField.text, let url = URL(string: urlString) else { return }
        let destination = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("tmp")
        
        dispatcher.downloadFuture(destination: destination, from: {
            return URLRequest(url: url, method: .get)
        }).progress({ [weak self] progress in
            print("PROGRESS: \(progress)")
            self?.progressView.progress = Float(progress)
        }).success({ [weak self] response in
            let url = response.data
            let data = try Data(contentsOf: url)
            let image = UIImage(data: data)
            self?.imageView.image = image
        }).error({ [weak self] error in
            self?.showAlert(title: "Whoops!", message: error.localizedDescription)
        }).completion({
            print("COMPLETED")
        }).send()
    }
    
    private func setupLayout() {
        view.addSubview(sendButton)
        view.addSubview(progressView)
        view.addSubview(imageView)
        view.addSubview(fileUrlTextField)
        
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        fileUrlTextField.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        fileUrlTextField.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 20).isActive = true
        fileUrlTextField.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor).isActive = true
        fileUrlTextField.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor).isActive = true
        
        sendButton.topAnchor.constraint(equalTo: fileUrlTextField.bottomAnchor, constant: 15).isActive = true
        sendButton.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor).isActive = true
        sendButton.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor).isActive = true
        
        progressView.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 15).isActive = true
        progressView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor).isActive = true
        
        imageView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 15).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -20).isActive = true
    }
}

extension DownloadViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let urlString = fileUrlTextField.text, URL(string: urlString) != nil {
            sendButton.isEnabled = true
        } else {
            sendButton.isEnabled = false
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentTextField = textField
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        currentTextField?.resignFirstResponder()
        return true
    }
}
