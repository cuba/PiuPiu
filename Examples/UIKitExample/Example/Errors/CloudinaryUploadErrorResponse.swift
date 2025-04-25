//
//  CloudinaryUploadErrorResponse.swift
//  Example
//
//  Created by Jacob Sikorski on 2019-07-04.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

public struct CloudinaryUploadErrorResponse: Decodable {
  public enum CodingKeys: String, CodingKey {
    case error = "error"
  }
  
  public let error: CloudinaryUploadErrorMessage
}

public struct CloudinaryUploadErrorMessage: Decodable {
  
  public enum CodingKeys: String, CodingKey {
    case message = "message"
  }
  
  public let message: String
}
