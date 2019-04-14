//
//  MultiPartRequest.swift
//  PewPew iOS
//
//  Created by Jacob Sikorski on 2019-03-27.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

/// A convenience Request object for submitting a multi-part request.
public struct MultiPartRequest: Request {
    public var method: HTTPMethod
    public var path: String
    public var queryItems: [URLQueryItem]
    public var headers: [String: String]
    public var httpBody: Data?
    
    /// Initialize this upload request.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use
    ///   - path: The path that will be appended to the baseURL on the `ServerProvider`.
    public init(method: HTTPMethod, path: String) {
        self.method = method
        self.path = path
        self.queryItems = []
        self.headers = [:]
    }
    
    /// Set the HTTP body using multi-part form data
    ///
    /// - Parameters:
    ///   - file: The file to attach. This file will be attached as-is
    ///   - fileName: The file name that will be used.
    ///   - mimeType: The mime type or otherwise known as Content-Type
    ///   - parameters: Any additional mult-part parameters to include
    mutating public func setHTTPBody(file: Data, fileFieldName: String = "file", fileName: String, mimeType: String, parameters: [String: String] = [:]) {
        let boundary = UUID().uuidString
        let contentType = "multipart/form-data; boundary=\(boundary)"
        let endBoundaryPart = String(format: "--%@--\r\n", boundary)
        var body = makeBody(file: file, fileFieldName: fileFieldName, fileName: fileName, mimeType: mimeType, parameters: parameters, boundary: boundary)
        body.append(endBoundaryPart.data(using: String.Encoding.utf8)!)
        
        headers["Content-Length"] = "\(body.count)"
        headers["Content-Type"] = contentType
        self.httpBody = body
    }
    
    /// Set the HTTP body using multi-part form data
    ///
    /// - Parameters:
    ///   - parameters: Any mult-part parameters to include
    mutating public func setHTTPBody(parameters: [String: String]) {
        let boundary = UUID().uuidString
        let contentType = "multipart/form-data; boundary=\(boundary)"
        let endBoundaryPart = String(format: "--%@--\r\n", boundary)
        var body = makeBody(parameters: parameters, boundary: boundary)
        body.append(endBoundaryPart.data(using: String.Encoding.utf8)!)
        
        headers["Content-Length"] = "\(body.count)"
        headers["Content-Type"] = contentType
        self.httpBody = body
    }
    
    private func makeBody(file: Data, fileFieldName: String, fileName: String, mimeType: String, parameters: [String: String], boundary: String) -> Data {
        var body = makeBody(parameters: parameters, boundary: boundary)
        
        // Add image data
        let boundaryPart = String(format: "--%@\r\n", boundary)
        let keyPart = String(format: "Content-Disposition:form-data; name=\"%@\"; filename=\"%@\"\r\n", fileFieldName, fileName)
        let valuePart = String(format: "Content-Type: %@\r\n\r\n", mimeType)
        let spacePart = String(format: "\r\n")
        
        body.append(boundaryPart.data(using: String.Encoding.utf8)!)
        body.append(keyPart.data(using: String.Encoding.utf8)!)
        body.append(valuePart.data(using: String.Encoding.utf8)!)
        body.append(file)
        body.append(spacePart.data(using: String.Encoding.utf8)!)
        
        return body
    }
    
    private func makeBody(parameters: [String: String], boundary: String) -> Data {
        var body = Data()
        
        // Add params (all params are strings)
        for (key, value) in parameters {
            let boundaryPart = String(format: "--%@\r\n", boundary)
            let keyPart = String(format: "Content-Disposition:form-data; name=\"%@\"\r\n\r\n", key)
            let valuePart = String(format: "%@\r\n", value)
            
            body.append(boundaryPart.data(using: String.Encoding.utf8)!)
            body.append(keyPart.data(using: String.Encoding.utf8)!)
            body.append(valuePart.data(using: String.Encoding.utf8)!)
        }
        
        return body
    }
}
