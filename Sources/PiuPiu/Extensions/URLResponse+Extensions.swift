//
//  File.swift
//  
//
//  Created by Jakub Sikorski on 2022-01-20.
//

import Foundation

extension URLResponse {
    /// A method to print the response in the console.
    /// **Warning** This should not be used in a production environment. You should place this call behind a macro such as `DEBUG`
    func makeResponseMarkdown(with urlRequest: URLRequest, data: Data?) -> String {
        var components: [String] = ["## RESPONSE"]

        if let httpResponse = self as? HTTPURLResponse {
            components.append("[\(urlRequest.httpMethod!)] (\(httpResponse.statusCode)) \(url!)")

            components.append("### Headers")
            for (key, value) in httpResponse.allHeaderFields {
                components.append("* \(key): \(value)")
            }
        } else {
            components.append("[\(urlRequest.httpMethod!)] \(url!)")
        }

        if let data = data {
            components.append("### Body")
            components.append("```json")
            do {
                let json = try decodeString(from: data, encoding: .utf8)
                components.append(json)
            } catch {
                components.append("\(error)")
            }
            components.append("```")
        }

        return components.joined(separator: "\n")
    }

    /// Attempt to deserialize the response data into a JSON string.
    ///
    /// - Parameter encoding: The string encoding type. The dafault is `.utf8`.
    /// - Returns: The decoded object
    /// - throws: `ResponseError.unexpectedEmptyResponse` if there is no data
    /// - throws: `ResponseError.failedToDecodeDataToString` if the data cannot be transformed into a string
    private func decodeString(from data: Data, encoding: String.Encoding = .utf8) throws -> String {
        // Attempt to deserialize the object.
        guard let string = String(data: data, encoding: encoding) else {
            throw ResponseError.failedToDecodeDataToString(encoding: encoding)
        }

        return string
    }
}
