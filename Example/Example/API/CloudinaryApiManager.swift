//
//  CloudinaryApiManager.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-07-04.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import PiuPiu

public enum FileType {
    case png
    case jpg
    case gif
    
    public var mimeType: String {
        switch self {
        case .jpg: return "image/jpg"
        case .png: return "image/png"
        case .gif: return "image/gif"
        }
    }
    
    public var fileName: String {
        switch self {
        case .jpg: return "image.jpg"
        case .png: return "image.png"
        case .gif: return "image.gif"
        }
    }
}

open class CloudinaryApiManager {
    let dispatcher: UploadDispatcher
    
    public init(dispatcher: UploadDispatcher) {
        self.dispatcher = dispatcher
    }
    
    open func uploadToCloudinary(file: Data, type: FileType, folderName: String) -> ResponseFuture<Response<Data?>> {
        let publicId = "\(folderName)/\(UUID().uuidString)"
        let path = "/v1_1/dvb4otyuk/image/upload"
        
        let parameters: [String: String] = [
            "upload_preset": "piupiu",
            "public_id": publicId
        ]
        
        return upload(file: file, type: type, path: path, parameters: parameters)
    }
    
    open func upload(file: Data, type: FileType, path: String, parameters: [String: String]) -> ResponseFuture<Response<Data?>> {
        let boundary = UUID().uuidString
        let contentType = "multipart/form-data; boundary=\(boundary)"
        let body = makeBody(file: file, type: type, parameters: parameters, boundary: boundary)
        let url = URL(string: "https://api.cloudinary.com")!.appendingPathComponent(path)
        
        return dispatcher.uploadFuture(with: body, from: {
            var request = URLRequest(url: url, method: .post)
            request.addValue("\(body.count)", forHTTPHeaderField: "Content-Length")
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
            return request
        })
    }
    
    private func makeBody(file: Data, type: FileType, parameters: [String: String], boundary: String) -> Data {
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
        let keyPart = String(format: "Content-Disposition:form-data; name=\"file\"; filename=\"%@\"\r\n", type.fileName)
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
