//
//  UploadsView.swift
//  Example
//
//  Created by Jacob Sikorski on 2025-04-22.
//

import SwiftUI
import SwiftData
import CloudinaryKit
import PhotosUI
import PiuPiu
import os.log

struct UploadsView: View {
  static let bytesFormatter = ByteCountFormatter()
  static let percentFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    return formatter
  }()
  
  @Environment(\.modelContext) private var modelContext
  @State private var pickerItems = [PhotosPickerItem]()
  @State private var imageFiles: [ImageFile] = []
  @State private var uploadTask: Task<Void, Never>?
  @State private var error: Error?
  @State private var bytesSent: [UUID: Int64] = [:]
  @State private var bytesExpectedToSend: [UUID: Int64] = [:]
  @State private var responses: [UUID: String] = [:]
  
  var totalBytesSent: Int64 {
    bytesSent.reduce(Int64(0), { partialResult, element in
      return partialResult + element.value
    })
  }
  
  var totalBytesExpectedToSend: Int64 {
    bytesExpectedToSend.reduce(Int64(0), { partialResult, element in
      return partialResult + element.value
    })
  }
  
  var percentSent: Double {
    guard totalBytesExpectedToSend > 0 else { return 0 }
    return Double(totalBytesSent) / Double(totalBytesExpectedToSend)
  }
  
  private let apiManager = CloudinaryApiManager(
    dispatcher: URLRequestDispatcher(session: URLSession(
      configuration: URLSessionConfiguration.ephemeral
    ))
  )
  
  // Always hold a strong reference to the dispatcher
  private let dispatcher = URLRequestDispatcher(
    session: URLSession(
      configuration: URLSessionConfiguration.ephemeral
    )
  )
  
  var body: some View {
    List {
      Section {
        PhotosPicker(selection: $pickerItems, matching: .images) {
          Label("Select Images", systemImage: "plus")
        }.onChange(of: pickerItems) { oldValue, newValue in
          guard !newValue.isEmpty else { return }
          upload(items: newValue)
        }
        
        if let error {
          Text(error.localizedDescription)
            .font(.caption).foregroundStyle(.red)
        }
        
        if totalBytesExpectedToSend > 0 {
          VStack {
            HStack {
              Text("\(Self.bytesFormatter.string(fromByteCount: totalBytesSent)) uploaded")
                .font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
              Text(Self.bytesFormatter.string(fromByteCount: totalBytesExpectedToSend))
                .font(.caption).foregroundStyle(.secondary)
              
              if let percent = Self.percentFormatter.string(from: NSNumber(value: percentSent)) {
                Text(percent).font(.caption).foregroundStyle(.tertiary)
              }
            }
            ProgressView(
              value: Double(totalBytesSent),
              total: Double(totalBytesExpectedToSend)
            ).progressViewStyle(.linear)
          }
        }
      }
      
      Section {
        ForEach(imageFiles) { imageFile in
          UploadedImageRow(
            imageFile: imageFile,
            totalBytesSent: bytesSent[imageFile.id],
            totalBytesExpectedToSend: bytesExpectedToSend[imageFile.id],
            response: responses[imageFile.id]
          )
        }
      }
    }
  }
  
  func upload(items: [PhotosPickerItem]) {
    uploadTask?.cancel()
    bytesSent.removeAll()
    bytesExpectedToSend.removeAll()
    
    uploadTask = Task {
      do {
        let files = try await items.parallelCompactMap { item in
          return try await item.loadTransferable(type: ImageFile.self)
        }
        
        imageFiles = files
        responses.removeAll()
        
        for file in files {
          bytesSent[file.id] = 0
          bytesExpectedToSend[file.id] = file.bytes
        }
        
        try await files.parallelForEach { file in
          do {
            try await upload(file: file)
          } catch {
            throw error
          }
        }
        
        pickerItems.removeAll()
      } catch {
        self.error = error
        self.pickerItems.removeAll()
      }
    }
  }
  
  private func upload(file: ImageFile) async throws {
    let data = try Data(contentsOf: file.localURL)
    
    for try await event in apiManager.makeStream(
      file: data,
      fileName: file.fileName,
      type: file.fileType,
      folderName: "test"
    ) {
      Logger.uploads.debug("""
        Event: \(String(describing: event))
        """)
      
      switch event {
      case .taskCreated:
        break
      case .uploadProgress(let task), .completed(let task):
        bytesSent[file.id] = task.countOfBytesSent
        bytesExpectedToSend[file.id] = task.countOfBytesExpectedToSend
        Logger.uploads.debug("""
          Progress: \(percentSent)
          """)
      case .downloadProgress:
        break
      case .response(_, let response):
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let response = try response
          .loadData()
          .log()
          .ensureHTTPResponse()
          .ensureBody()
          // Lets prettify the JSON
          .map { data -> Data in
            return try JSONSerialization.data(
              withJSONObject: JSONSerialization.jsonObject(with: data),
              options: .prettyPrinted
            )
          }
          .ensureStringBody(encoding: .utf8)
        
        Task { @MainActor in
          responses[file.id] = response.body
        }
      }
    }
  }
}

struct UploadedImageRow: View {
  let imageFile: ImageFile
  let totalBytesSent: Int64?
  let totalBytesExpectedToSend: Int64?
  let response: String?
  
  var percentSent: Double {
    guard let totalBytesExpectedToSend else { return 0 }
    guard totalBytesExpectedToSend > 0 else { return 0 }
    return Double(totalBytesSent ?? 0) / Double(totalBytesExpectedToSend)
  }
  
  var body: some View {
    VStack(alignment: .center) {
      imageFile.image.resizable().scaledToFit()
      
      if let response {
        Text(UploadsView.bytesFormatter.string(fromByteCount: imageFile.bytes))
          .font(.caption).foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .trailing)
        
        Text(response).font(.caption).foregroundStyle(.secondary)
      } else if let totalBytesExpectedToSend, totalBytesExpectedToSend > 0 {
        HStack {
          Text("\(UploadsView.bytesFormatter.string(fromByteCount: totalBytesSent ?? 0)) uploaded")
            .font(.caption).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
          Text(UploadsView.bytesFormatter.string(fromByteCount: totalBytesExpectedToSend ))
            .font(.caption).foregroundStyle(.secondary)
          
          if let percent = UploadsView.percentFormatter.string(from: NSNumber(value: percentSent)) {
            Text(percent).font(.caption).foregroundStyle(.tertiary)
          }
        }
      
        ProgressView(
          value: Double(totalBytesSent ?? 0),
          total: Double(totalBytesExpectedToSend)
        ).progressViewStyle(.linear)
      }
    }
  }
}

#Preview {
  UploadsView()
}

enum TransferError: Error {
  case importFailed
}

struct ImageFile: Sendable, Transferable, Identifiable {
  let id: UUID = UUID()
  let image: Image
  let localURL: URL
  let fileType: ImageFileType
  let fileName: String
  let bytes: Int64
  
  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(importedContentType: .image) { received in
      guard let fileType = fileType(forURL: received.file) else {
        throw TransferError.importFailed
      }
      
      let fileName = received.file.lastPathComponent
      let copyURL = URL.temporaryDirectory.appending(path: fileName)
      if FileManager.default.fileExists(atPath: copyURL.path) {
        try? FileManager.default.removeItem(at: copyURL)
      }
      
      try FileManager.default.copyItem(at: received.file, to: copyURL)
      let data = try Data(contentsOf: copyURL)
      guard let uiImage = UIImage(data: data) else {
        throw TransferError.importFailed
      }
      
      let fileAttributes = try? FileManager.default.attributesOfItem(atPath: copyURL.path)
      let bytes = fileAttributes?[.size] as? Int64
      
      return Self.init(
        image: Image(uiImage: uiImage),
        localURL: copyURL,
        fileType: fileType,
        fileName: fileName,
        bytes: bytes ?? 0
      )
    }
  }
  
  static func fileType(forURL url: URL) -> ImageFileType? {
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
