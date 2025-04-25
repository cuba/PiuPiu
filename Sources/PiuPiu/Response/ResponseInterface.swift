//
//  ResponseInterface.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-15.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation
import os.log

public struct ResponseLoggingOptions: OptionSet, Sendable {
  public let rawValue: Int
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  public static let logRequest = Self(rawValue: 1 << 0)
  public static let logResponse = Self(rawValue: 1 << 1)
  public static let detailed = Self(rawValue: 1 << 2)
  public static let prettyPrinted = Self(rawValue: 1 << 3)
  public static let `default`: Self = [.logRequest, .logResponse, .detailed, .prettyPrinted]
}

/// The protocol wrapping the response object.
public protocol ResponseInterface: Sendable {
  associatedtype Body: Sendable
  
  /// The data object that is attached to this response as specified by the user
  var body: Body { get }
  
  /// The `URLRequest` that is returned on a successful response.
  /// **Note**: successful responses includes all responses incuding ones with `5xx` status codes
  var urlResponse: URLResponse { get }
  
  /// The original `URLRequest` that was used to create the request.
  var urlRequest: URLRequest { get }
}

public extension ResponseInterface where Body == Data? {
  /// Attempt to unwrap the response data.
  ///
  /// - Returns: The unwrapped object
  /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
  func unwrapData() throws -> Data {
    // Check if we have the data we need
    guard let unwrappedData = body else {
      throw ResponseError.unexpectedEmptyResponse
    }
    
    return unwrappedData
  }
}

public extension ResponseInterface where Body == Data {
  /// Attempt to deserialize the response data into a JSON string.
  ///
  /// - Parameter encoding: The string encoding type. The dafault is `.utf8`.
  /// - Returns: The decoded object
  /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
  /// - throws: `ResponseError.failedToDecodeDataToString` if the data cannot be transformed into a string
  func decodeString(encoding: String.Encoding = .utf8) throws -> String {
    // Attempt to deserialize the object.
    guard let string = String(data: body, encoding: encoding) else {
      throw ResponseError.failedToDecodeDataToString(encoding: encoding)
    }
    
    return string
  }
  
  /// Attempt to decode a JSON object (`Any`) from the response data.
  ///
  /// - Parameter options: Reading options. Default is set to `.mutableContainers`.
  /// - Returns: JSON object as `Any`
  /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
  /// - throws: An error if any value throws an error during decoding.
  func decodeJSONObject(options: JSONSerialization.ReadingOptions = .mutableContainers) throws -> Any {
    return try JSONSerialization.jsonObject(with: body, options: options)
  }
  
  /// Attempt to decode the response data into a `Decodable` object.
  ///
  /// - Parameters:
  ///   - type: The `Decodable` type to decode
  ///   - dateDecodingStrategy: The default date encoding strategy to use.
  /// - Returns: The decoded object
  /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
  /// - throws: An error if any value throws an error during decoding.
  func decode<D: Decodable>(_ type: D.Type, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy) throws  -> D {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = dateDecodingStrategy
    return try decode(type, using: decoder)
  }
  
  /// Attempt to decode the response data into a `Decodable` object.
  ///
  /// - Parameters:
  ///   - type: The `Decodable` type to decode
  ///   - decoder: The decoder to use.
  /// - Returns: The decoded object
  /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
  /// - throws: An error if any value throws an error during decoding.
  func decode<D: Decodable>(_ type: D.Type, using decoder: JSONDecoder = JSONDecoder()) throws  -> D {
    return try decoder.decode(type, from: body)
  }
  
  /// Attempt to decode the response data into a `Decodable` object.
  ///
  /// - Parameters:
  ///   - type: The `Decodable` type to decode
  ///   - decoder: The decoder to use.
  /// - Returns: The decoded object
  /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
  /// - throws: An error if any value throws an error during decoding.
  func decodeAsync<D: Decodable & Sendable>(
    _ type: D.Type,
    using decoder: JSONDecoder = JSONDecoder(),
    priority: TaskPriority? = nil
  ) async throws -> D {
    let body = self.body
    return try await Task.detached(priority: priority) {
      return try decoder.decode(type, from: body)
    }.value
  }
}

public extension ResponseInterface where Body == Data? {
  /// Attempt to decode the response data into a `Decodable` object.
  ///
  /// - Parameters:
  ///   - type: The `Decodable` type to decode
  ///   - decoder: The decoder to use.
  /// - Returns: The decoded object
  /// - throws: An error if any value throws an error during decoding.
  func decodeAsyncIfPresent<D: Decodable & Sendable>(
    _ type: D.Type,
    using decoder: JSONDecoder = JSONDecoder(),
    priority: TaskPriority? = nil
  ) async throws  -> D? {
    guard let data = self.body else { return nil }
    return try await Task.detached(priority: priority) {
      return try decoder.decode(type, from: data)
    }.value
  }
  
  /// Attempt to decode the response data into a `Decodable` object.
  ///
  /// - Parameters:
  ///   - type: The `Decodable` type to decode
  ///   - decoder: The decoder to use.
  /// - Returns: The decoded object
  /// - throws: An error if any value throws an error during decoding.
  func decodeIfPresent<D: Decodable>(
    _ type: D.Type,
    using decoder: JSONDecoder = JSONDecoder()
  ) throws  -> D? {
    guard let data = self.body else { return nil }
    return try decoder.decode(type, from: data)
  }
  
  /// A method to print the request and response in the console.
  func log(options: ResponseLoggingOptions = .default) -> Self {
    if options.contains(.logRequest) {
      logRequest(
        logger: Logger.network,
        isDetailed: options.contains(.detailed),
        prettyPrinted: options.contains(.prettyPrinted)
      )
    }
    
    if options.contains(.logResponse) {
      logResponse(
        logger: Logger.network,
        isDetailed: options.contains(.detailed),
        prettyPrinted: options.contains(.prettyPrinted)
      )
    }
    return self
  }
  
  /// A method to print the request in the console.
  @discardableResult
  func logRequest(logger: Logger, isDetailed: Bool, prettyPrinted: Bool = false) -> Self {
    guard isDetailed else {
      logger.debug(
        """
        ## Request ##
        [`\(urlRequest.httpMethod!, privacy: .public)`] `\(urlRequest.url!, privacy: .private)`
        """
      )
      
      return self
    }
    
    let headersString = urlRequest.allHTTPHeaderFields?.map({ (key, value) -> String in
      return "* `\(key)`: `\(value)`"
    }).sorted(by: { $0 < $1} ).joined(separator: "\n")
    
    let bodyString: String?
    if var httpBody = urlRequest.httpBody {
      if prettyPrinted {
        do {
          httpBody = try JSONSerialization.data(
            withJSONObject: JSONSerialization.jsonObject(with: httpBody),
            options: .prettyPrinted
          )
        } catch {
          // Do nothing
        }
      }
      
      if let json = String(data: httpBody, encoding: .utf8) {
        bodyString = json
      } else {
        let string = httpBody.base64EncodedString()
        if !string.isEmpty {
          bodyString = httpBody.base64EncodedString()
        } else {
          bodyString = "\(httpBody.count) bytes"
        }
      }
    } else {
      bodyString = nil
    }
    
    logger.debug(
      """
      ## Request ##
      [`\(urlRequest.httpMethod!, privacy: .public)`] `\(urlRequest.url!, privacy: .private)`
      
      ### Headers ###
      ```
      \(headersString ?? "[:]", privacy: .private)
      ```
      ### Body ###
      ```
      \(bodyString ?? "", privacy: .private)
      ```
      """
    )
    return self
  }
  
  /// A method to print the response in the console.
  @discardableResult
  func logResponse(logger: Logger, isDetailed: Bool, prettyPrinted: Bool = false) -> Self {
    guard isDetailed else {
      if let httpResponse = urlResponse as? HTTPURLResponse {
        logger.debug(
          """
          ## Response ##
          [\(urlRequest.httpMethod!)] (\(httpResponse.statusCode)) `\(urlResponse.url!.absoluteString, privacy: .private)`
          """
        )
      } else {
        logger.debug(
          """
          ## Response ## 
          [`\(urlRequest.httpMethod!)`] `\(urlResponse.url!.absoluteString, privacy: .private)`
          """
        )
      }
      
      return self
    }
    
    let bodyString: String?
    if var httpBody = body {
      if prettyPrinted {
        do {
          httpBody = try JSONSerialization.data(
            withJSONObject: JSONSerialization.jsonObject(with: httpBody),
            options: .prettyPrinted
          )
        } catch {
          // Do nothing
        }
      }
      
      if let json = String(data: httpBody, encoding: .utf8) {
        bodyString = json
      } else {
        let string = httpBody.base64EncodedString()
        
        if !string.isEmpty {
          bodyString = httpBody.base64EncodedString()
        } else {
          bodyString = "\(httpBody.count) bytes"
        }
      }
    } else {
      bodyString = nil
    }
    
    if let httpResponse = urlResponse as? HTTPURLResponse {
      let headersString = httpResponse.allHeaderFields.map({ (key, value) -> String in
        return "* `\(key)`: `\(value)`"
      }).sorted(by: { $0 < $1} ).joined(separator: "\n")
      
      logger.debug(
        """
        ## Response ##
        [\(urlRequest.httpMethod!)] (\(httpResponse.statusCode)) `\(urlResponse.url!.absoluteString, privacy: .private)`
        
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
        [`\(urlRequest.httpMethod!)`] `\(urlResponse.url!.absoluteString, privacy: .private)`
        ### Body: \(bodyString ?? "", privacy: .private)
        """
      )
    }
    return self
  }
}
