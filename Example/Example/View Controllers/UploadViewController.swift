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
    
    lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        return imagePicker
    }()
    
    lazy var filePicker: UIDocumentPickerViewController = {
        let filePicker = UIDocumentPickerViewController(documentTypes: ["public.image"], in: .import)
        filePicker.delegate = self
        filePicker.allowsMultipleSelection = true
        return filePicker
    }()
    
    private let apiManager: CloudinaryApiManager
    private var pendingTasks: Set<URLSessionTask> = []
    
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
        view.backgroundColor = UIColor.groupedBackground
        title = "Upload"
        setupLayout()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // dispatcher.invalidateAndCancel()
    }
    
    @objc
    private func tappedSelectButton() {
        #if targetEnvironment(macCatalyst)
        showFilePicker()
        #else
        showSourcePicker()
        #endif
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
    
    private func showFilePicker() {
        present(filePicker, animated: true, completion: nil)
    }
    
    private func showSourcePicker() {
        let availableSourceTypes = UIImagePickerController.filterAvailable(sourceTypes: [.camera, .photoLibrary])
        let alertController = UIAlertController(title: "Select Source", message: nil, preferredStyle: .actionSheet)
        
        for sourceType in availableSourceTypes {
            alertController.addAction(UIAlertAction(title: sourceType.title, style: .default, handler: { _ in
                self.showSourcePicker(for: sourceType)
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "Files", style: .default, handler: { _ in
            self.showFilePicker()
        }))
        
        alertController.popoverPresentationController?.sourceView = selectButton
        alertController.popoverPresentationController?.sourceRect = selectButton.frame
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func showSourcePicker(for type: UIImagePickerController.SourceType) {
        switch type {
        case .camera:
            showCamera()
        case .photoLibrary:
            showPhotoLibrary()
        case .savedPhotosAlbum:
            // Not supported
            break
        @unknown default:
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
    
    private func upload(files: [(data: Data, type: FileType)]) {
        pendingTasks.forEach { $0.cancel() }
        self.progressView.progress = 0
        
        apiManager.uploadToCloudinary(files: files, folderName: "test")
            .updated { [weak self] task in
                guard task.state == .completed || task.state == .running else { return }
                self?.pendingTasks.insert(task)
                
                if let percent = self?.pendingTasks.averagePercentTransferred {
                    print("PROGRESS: \(percent)")
                    self?.progressView.progress = percent
                }
            }
            .response { [weak self] response in
                let strings = try response.map({ try $0.decodeString(encoding: .utf8) })
                self?.textView.text = strings.joined(separator: "\n")
            }
            .error { [weak self] error in
                self?.showAlert(title: "Whoops!", message: error.localizedDescription)
            }
            .completion { [weak self] in
                self?.progressView.progress = 1
                self?.pendingTasks = []
            }
            .send()
    }
    
    private func upload(data: Data, type: FileType) {
        pendingTasks.forEach { $0.cancel() }
        self.progressView.progress = 0
        
        apiManager.uploadToCloudinary(file: data, type: type, folderName: "test")
            .updated { [weak self] task in
                guard task.state == .completed || task.state == .running else { return }
                self?.pendingTasks.insert(task)
                
                if let percent = self?.pendingTasks.averagePercentTransferred {
                    print("PROGRESS: \(percent)")
                    self?.progressView.progress = percent
                }
            }
            .response { [weak self] response in
                let string = try response.decodeString(encoding: .utf8)
                self?.textView.text = string
            }
            .error { [weak self] error in
                self?.showAlert(title: "Whoops!", message: error.localizedDescription)
            }
            .send()
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension UploadViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let mediaUrl = info[.imageURL] as? URL ?? info[.mediaURL] as? URL {
            guard let data = try? Data(contentsOf: mediaUrl) else { return }
            guard let type = fileType(forURL: mediaUrl) else {
                assertionFailure("Unsupported type")
                return
            }
            
            upload(data: data, type: type)
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
    var title: String? {
        switch self {
        case .camera:           return "Camera"
        case .photoLibrary:     return "Photo Library"
        case .savedPhotosAlbum: return "Photo Album"
        @unknown default:       return nil
        }
    }
}

extension UIImagePickerController {
    static func filterAvailable(sourceTypes: [UIImagePickerController.SourceType]) -> [UIImagePickerController.SourceType] {
        return sourceTypes.filter({ self.isSourceTypeAvailable($0) })
    }
}

extension UploadViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let files = urls.compactMap { url -> (Data, FileType)? in
            guard let type = fileType(forURL: url) else {
                assertionFailure("Unsupported type")
                return nil
            }
            
            guard let data = try? Data(contentsOf: url) else { return nil }
            return (data, type)
        }
        
        upload(files: files)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        guard let data = try? Data(contentsOf: url) else { return }
        guard let type = fileType(forURL: url) else {
            assertionFailure("Unsupported type")
            return
        }
        
        upload(data: data, type: type)
    }
    
    private func fileType(forURL url: URL) -> FileType? {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "jpg", "jpeg":
            return .jpg
        case "png":
            return .png
        case "gif":
            return .gif
        default:
            return nil
        }
    }
}
