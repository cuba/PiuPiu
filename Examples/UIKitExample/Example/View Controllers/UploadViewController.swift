//
//  UploadViewController.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-07-03.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import UIKit
import PiuPiu
import CloudinaryKit

class UploadViewController: BaseViewController {
  struct ImageFile: Sendable {
    let data: Data
    let type: ImageFileType
  }
  
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
    let filePicker = UIDocumentPickerViewController(forOpeningContentTypes: [.image])
    filePicker.delegate = self
    filePicker.allowsMultipleSelection = true
    return filePicker
  }()
  
  private let apiManager: CloudinaryApiManager
  private var uploadTask: Task<Void, Never>? = nil
  
  init() {
    let dispatcher = URLRequestDispatcher(session: URLSession(
      configuration: URLSessionConfiguration.ephemeral
    ))
    apiManager = CloudinaryApiManager(dispatcher: dispatcher)
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.systemGroupedBackground
    title = "Upload"
    setupLayout()
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
  
  private func upload(files: [ImageFile]) {
    progressView.progress = 0
    var results: [String?] = Array(repeating: nil, count: files.count)
    let progressIncrement = 1.0 / Float(files.count)
    
    uploadTask?.cancel()
    uploadTask = Task {
      do {
        // For parallel requests, put each request in its own Task or in a TaskGroup
        // (parallelForEach is a custom extension that helps with using a TaskGroup)
        // Since results come in a random order, you will have to manage order yourself.
        // Note: Task or TaskGroup requires that files are Sendable
        try await files.enumerated().parallelForEach { index, file in
          let response = try await self.uploadToCloudinary(file: file.data, type: file.type)
          guard !Task.isCancelled else { return }
          
          // TaskGroup (which is used in parallelForEach) requires that the callback is Sendable
          // Hence we need to move to MainActor when modifying the view.
          // We should also check cancellations.
          Task { @MainActor in
            guard !Task.isCancelled else { return }
            results[index] = response.body
            let availableResults = results.compactMap(\.self)
            self.progressView.progress = Float(availableResults.count) * progressIncrement
            self.textView.text = availableResults.joined(separator: "\n\n")
          }
        }
      } catch {
        guard !Task.isCancelled else { return }
        textView.text = error.localizedDescription
        progressView.progress = 0
      }
    }
  }
  
  private func upload(file: Data, type: ImageFileType) {
    self.progressView.progress = 0
    
    uploadTask?.cancel()
    uploadTask = Task {
      do {
        let response = try await uploadToCloudinary(file: file, type: type)
        guard !Task.isCancelled else { return }
        textView.text = response.body
        self.progressView.progress = 1
      } catch {
        guard !Task.isCancelled else { return }
        textView.text = error.localizedDescription
        self.progressView.progress = 0
      }
    }
  }
  
  private func uploadToCloudinary(file: Data, type: ImageFileType) async throws -> HTTPResponse<String> {
    return try await self.apiManager.uploadToCloudinary(
      file: file,
      fileName: "image.\(type.fileExtension)",
      type: type,
      folderName: "test"
    ).log()
      .ensureHTTPResponse()
      .ensureBody()
      .ensureValidResponse()
      .map { data -> Data in
        // Lets prettify the JSON
        return try JSONSerialization.data(
          withJSONObject: JSONSerialization.jsonObject(with: data),
          options: .prettyPrinted
        )
      }
      .ensureStringBody()
  }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension UploadViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    let mediaURL = info[.imageURL] as? URL ?? info[.mediaURL] as? URL
    
    if let mediaURL = mediaURL {
      guard let data = try? Data(contentsOf: mediaURL) else { return }
      guard let type = fileType(forURL: mediaURL) else {
        assertionFailure("Unsupported type")
        return
      }
      
      upload(file: data, type: type)
    } else if let image = info[.originalImage] as? UIImage {
      guard let data = image.jpegData(compressionQuality: 1) else { return }
      upload(file: data, type: .jpg)
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
    let files = urls.compactMap { url -> ImageFile? in
      guard let type = fileType(forURL: url) else {
        assertionFailure("Unsupported type")
        return nil
      }
      
      guard let data = try? Data(contentsOf: url) else { return nil }
      return ImageFile(data: data, type: type)
    }
    
    upload(files: files)
  }
  
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
    guard let data = try? Data(contentsOf: url) else { return }
    guard let type = fileType(forURL: url) else {
      assertionFailure("Unsupported type")
      return
    }
    
    upload(file: data, type: type)
  }
  
  private func fileType(forURL url: URL) -> ImageFileType? {
    let fileExtension = url.pathExtension.lowercased()
    
    switch fileExtension {
    case "jpg", "jpeg":
      return .jpg
    case "png":
      return .png
    case "gif":
      return .gif
    case "heic":
      return .heic
    default:
      return nil
    }
  }
}
