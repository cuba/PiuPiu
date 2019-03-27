//
//  Promise+Extensions.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2019-02-16.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

extension Promise {
    
    /// Calls the start() method on the promise
    ///
    /// - Returns: This promise
    @discardableResult
    public func send() -> Promise<T, E> {
        return start()
    }
}

public extension Promise where T == SuccessResponse<Data?>, E == ErrorResponse<Data?> {
    public func printResponse() -> Promise<T, E> {
        return then({ response in
            print("===========================================")
            response.printRequest()
            print("-------------------------------------------")
            response.printResponse()
            print("===========================================")
            return response
        }).thenFailure({ response in
            print("===========================================")
            response.printRequest()
            print("-------------------------------------------")
            response.printResponse()
            print("===========================================")
            return response
        })
    }
}
