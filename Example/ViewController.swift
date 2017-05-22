//
//  ViewController.swift
//  Example
//
//  Created by Jacob Sikorski on 2017-05-22.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import UIKit
import NetworkKit

class ViewController: UIViewController {
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var baseUrlTextField: UITextField!
    @IBOutlet weak var pathTextField: UITextField!
    
    fileprivate var currentTextField: UITextField?
    private var serializer: NetworkSerializer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the NetworkKit
        let dispatcher = NetworkDispatcher(serverProvider: self)
        serializer = NetworkSerializer(dispatcher: dispatcher)
        
        // Configure the Text Fields
        baseUrlTextField.delegate = self
        pathTextField.delegate = self
    }
    
    @IBAction func sendAction(_ sender: Any) {
        currentTextField?.resignFirstResponder()
        
        let request = JSONRequest(method: .get, path: pathTextField.text ?? "")
        self.textView.text = ""
        
        serializer.send(request, successHandler: { (data: Any?) in
            if let data = data {
                self.textView.text = "\(data)"
            } else {
                self.textView.text = ""
            }
        }, errorHandler: { error in
            self.textView.text = error.localizedDescription
        }, completionHandler: {
            // Hide spinner
        })
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.baseUrlTextField {
            pathTextField.becomeFirstResponder()
        } else if let urlString = baseUrlTextField.text, URL(string: urlString) != nil {
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

extension ViewController: ServerProvider {
    var baseURL: URL {
        return URL(string: baseUrlTextField.text!)!
    }
}
