//
//  File.swift
//  
//
//  Created by Jakub Sikorski on 2022-01-20.
//

import Foundation
import os.log

extension URLResponse {
  public func log(logger: Logger, urlRequest: URLRequest, body: Data?, isDetailed: Bool) {
    guard isDetailed else {
      if let httpResponse = self as? HTTPURLResponse {
        logger.debug(
          """
          ## Response ##
          [\(urlRequest.httpMethod!)] (\(httpResponse.statusCode)) `\(self.url!.absoluteString, privacy: .private)`
          """
        )
      } else {
        logger.debug(
          """
          ## Response ## 
          [`\(urlRequest.httpMethod!)`] `\(self.url!.absoluteString, privacy: .private)`
          """
        )
      }
      
      return
    }
    
    let bodyString: String?
    if let httpBody = body {
      if let json = String(data: httpBody, encoding: .utf8) {
        bodyString = json
      } else {
        bodyString = httpBody.base64EncodedString()
      }
    } else {
      bodyString = nil
    }
    
    if let httpResponse = self as? HTTPURLResponse {
      let headersString = httpResponse.allHeaderFields.map({ (key, value) -> String in
        return "* `\(key)`: `\(value)`"
      }).sorted(by: { $0 < $1} ).joined(separator: "\n")
      
      logger.debug(
        """
        ## Response ##
        [\(urlRequest.httpMethod!)] (\(httpResponse.statusCode)) `\(self.url!.absoluteString, privacy: .private)`
        
        ### Headers ###
        ```
        \(headersString, privacy: .private)
        ```
        ### Body ###
        ```
        \(bodyString ?? "", privacy: .private)
        ```
        """
      )
    } else {
      logger.debug(
        """
        ### Response: 
        [`\(urlRequest.httpMethod!)`] `\(self.url!.absoluteString, privacy: .private)`
        ### Body: \(bodyString ?? "", privacy: .private)
        """
      )
    }
  }
}
