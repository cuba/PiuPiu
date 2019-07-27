//
//  UploadViewController.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-07-03.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import UIKit
import PiuPiu

class UploadViewController: BaseViewController {
    lazy var selectButton: UIButton = {
        let button = UIButton()
        button.setTitle("Select File", for: .normal)
        button.addTarget(self, action: #selector(tappedSelectButton), for: .touchUpInside)
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
    
    lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        return imagePicker
    }()
    
    private let apiManager: CloudinaryApiManager
    
    init() {
        let dispatcher = URLRequestDispatcher()
        apiManager = CloudinaryApiManager(dispatcher: dispatcher)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        (apiManager.dispatcher as? URLRequestDispatcher)?.invalidateAndCancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.groupTableViewBackground
        title = "Upload"
        setupLayout()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // dispatcher.invalidateAndCancel()
    }
    
    @objc
    private func tappedSelectButton() {
        showMediaPicker()
    }
    
    private func setupLayout() {
        view.addSubview(selectButton)
        view.addSubview(progressView)
        view.addSubview(textView)
        
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        selectButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 20).isActive = true
        selectButton.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor).isActive = true
        selectButton.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor).isActive = true
        
        progressView.topAnchor.constraint(equalTo: selectButton.bottomAnchor, constant: 15).isActive = true
        progressView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor).isActive = true
        
        textView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 15).isActive = true
        textView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor).isActive = true
        textView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor).isActive = true
        textView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -20).isActive = true
    }
    
    private func showMediaPicker() {
        let availableSourceTypes = UIImagePickerController.filterAvailable(sourceTypes: [.camera, .photoLibrary])
        
        guard availableSourceTypes.count > 1 else {
            guard let sourceType = availableSourceTypes.first else { return }
            showMediaPicker(for: sourceType)
            return
        }
        
        let alertController = UIAlertController(title: "Select Source", message: nil, preferredStyle: .actionSheet)
        
        for sourceType in availableSourceTypes {
            alertController.addAction(UIAlertAction(title: sourceType.title, style: .default, handler: { _ in
                self.showMediaPicker(for: sourceType)
            }))
        }
        
        alertController.popoverPresentationController?.sourceView = selectButton
        alertController.popoverPresentationController?.sourceRect = selectButton.frame
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    }
    
    private func showMediaPicker(for type: UIImagePickerController.SourceType) {
        switch type {
        case .camera:
            showCamera()
        case .photoLibrary:
            showPhotoLibrary()
        case .savedPhotosAlbum:
            // Not supported
            break
        }
    }
    
    private func showPhotoLibrary() {
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func showCamera() {
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func upload(data: Data, type: FileType) {
        apiManager.uploadToCloudinary(file: data, type: type, folderName: "test")
            .progress({ [weak self] progress in
                print("PROGRESS: \(progress)")
                self?.progressView.progress = progress
            })
            .response({ [weak self] response in
                let string = try response.decodeString(encoding: .utf8)
                self?.textView.text = string
            })
            .error({ [weak self] error in
                self?.showAlert(title: "Whoops!", message: error.localizedDescription)
            })
            .send()
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension UploadViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let mediaUrl = info[.imageURL] as? URL {
            guard let data = try? Data(contentsOf: mediaUrl) else { return }
            let pathExtension = mediaUrl.pathExtension
            
            switch pathExtension {
            case "jpg", "jpeg":
                upload(data: data, type: .jpg)
            case "png":
                upload(data: data, type: .png)
            case "gif":
                upload(data: data, type: .gif)
            default:
                break
            }
        } else if let mediaUrl = info[.mediaURL] as? URL {
            guard let data = try? Data(contentsOf: mediaUrl) else { return }
            upload(data: data, type: .jpg)
        } else if let image = info[.originalImage] as? UIImage {
            guard let data = image.jpegData(compressionQuality: 1) else { return }
            upload(data: data, type: .jpg)
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension UploadViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

extension UIImagePickerController.SourceType {
    var title: String {
        switch self {
        case .camera:           return "Camera"
        case .photoLibrary:     return "Photo Library"
        case .savedPhotosAlbum: return "Photo Album"
        }
    }
}

extension UIImagePickerController {
    static func filterAvailable(sourceTypes: [UIImagePickerController.SourceType]) -> [UIImagePickerController.SourceType] {
        return sourceTypes.filter({ self.isSourceTypeAvailable($0) })
    }
}
