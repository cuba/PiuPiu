//
//  CloudinaryApiManager.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-07-04.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import PiuPiu
import os.log

/// Image file type.
///
/// List of available image types can be found [here](https://www.iana.org/assignments/media-types/media-types.xhtml#image)
public enum ImageFileType: String, Sendable, Codable {
  case png = "image/jpg"
  case jpg = "image/png"
  case gif = "image/gif"
  case heic = "image/heic"
  
  public var mimeType: String {
    rawValue
  }
  
  public var fileExtension: String {
    switch self {
    case .jpg: return "jpg"
    case .png: return "png"
    case .gif: return "gif"
    case .heic: return "heic"
    }
  }
}

@MainActor public class CloudinaryApiManager {
  public enum Endpoint: String {
    case imageUpload = "/v1_1/dvb4otyuk/image/upload"
    case imageDestroy = "v1_1/dvb4otyuk/image/destroy"
  }
  
  static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.jacobsikorski.CloudinaryKit",
    category: "CloudinaryApiManager"
  )
  
  public static let baseURL = URL(string: "https://api.cloudinary.com")!
  public let dispatcher: URLRequestDispatcher
  
  public init(dispatcher: URLRequestDispatcher) {
    self.dispatcher = dispatcher
  }
  
  public func makeStream(
    file: Data,
    fileName: String,
    type: ImageFileType,
    folderName: String
  ) -> URLRequestStream<URLSessionUploadTask> {
    let publicId = "\(folderName)/\(UUID().uuidString)"
    
    let parameters: [String: String] = [
      "upload_preset": "piupiu",
      "public_id": publicId
    ]
    
    let boundary = UUID().uuidString
    let body = Self.uploadBody(file: file, fileName: fileName, type: type, parameters: parameters, boundary: boundary)
    let request = Self.uploadRequest(body: body, boundary: boundary)
    return dispatcher.session.uploadStream(with: request, from: body)
  }
  
  public func uploadToCloudinary(
    file: Data,
    fileName: String,
    type: ImageFileType,
    folderName: String
  ) async throws -> Response<Data?> {
    let publicId = "\(folderName)/\(UUID().uuidString)"
    let endpoint = Endpoint.imageUpload
    
    let parameters: [String: String] = [
      "upload_preset": "piupiu",
      "public_id": publicId
    ]
    
    return try await upload(
      file: file,
      fileName: fileName,
      type: type,
      endpoint: endpoint,
      parameters: parameters
    )
  }
  
  private func upload(
    file: Data,
    fileName: String,
    type: ImageFileType,
    endpoint: Endpoint,
    parameters: [String: String]
  ) async throws -> Response<Data?> {
    let boundary = UUID().uuidString
    let body = Self.uploadBody(file: file, fileName: fileName, type: type, parameters: parameters, boundary: boundary)
    let request = Self.uploadRequest(body: body, boundary: boundary)
    return try await dispatcher.upload(for: request, from: body).log()
  }
  
  private static func makeRequest(
    endpoint: Endpoint
  ) -> URLRequest {
    let url = baseURL.appendingPathComponent(endpoint.rawValue)
    return URLRequest(url: url, method: .post)
  }
  
  public static func destroyRequest(
    assetId: String
  ) -> URLRequest {
    var request = makeRequest(endpoint: .imageDestroy)
    request.httpBody = imageDestroyBody(assetId: assetId)
    return request
  }
  
  private static func uploadRequest(
    body: Data,
    boundary: String
  ) -> URLRequest {
    var request = makeRequest(endpoint: .imageUpload)
    let contentType = "multipart/form-data; boundary=\(boundary)"
    request.addValue("\(body.count)", forHTTPHeaderField: "Content-Length")
    request.addValue(contentType, forHTTPHeaderField: "Content-Type")
    return request
  }
  
  private static func imageDestroyBody(
    assetId: String
  ) -> Data? {
    "asset_id=\(assetId)".data(using: .utf8)
  }
  
  private static func uploadBody(
    file: Data,
    fileName: String,
    type: ImageFileType,
    parameters: [String: String],
    boundary: String
  ) -> Data {
    var body = Data()
    
    // Add params (all params are strings)
    for (key, value) in parameters {
      let boundaryPart = String(format: "--%@\r\n", boundary)
      let keyPart = String(format: "Content-Disposition:form-data; name=\"%@\"\r\n\r\n", key)
      let valuePart = String(format: "%@\r\n", value)
      
      #if DEBUG
      print("\(boundaryPart)\(keyPart)\(valuePart)")
      #endif
      
      body.append(boundaryPart.data(using: String.Encoding.utf8)!)
      body.append(keyPart.data(using: String.Encoding.utf8)!)
      body.append(valuePart.data(using: String.Encoding.utf8)!)
    }
    
    // Add image data
    let boundaryPart = String(format: "--%@\r\n", boundary)
    let keyPart = String(format: "Content-Disposition:form-data; name=\"file\"; filename=\"%@\"\r\n", fileName)
    let valuePart = String(format: "Content-Type: %@\r\n\r\n", type.mimeType)
    let spacePart = String(format: "\r\n")
    let endBoundaryPart = String(format: "--%@--\r\n", boundary)
    
    #if DEBUG
    print("\(boundaryPart)\(keyPart)\(valuePart)file\(spacePart)\(endBoundaryPart)")
    #endif
    
    body.append(boundaryPart.data(using: String.Encoding.utf8)!)
    body.append(keyPart.data(using: String.Encoding.utf8)!)
    body.append(valuePart.data(using: String.Encoding.utf8)!)
    body.append(file)
    body.append(spacePart.data(using: String.Encoding.utf8)!)
    body.append(endBoundaryPart.data(using: String.Encoding.utf8)!)
    
    return body
  }
}
