//
//  ResponseFutureTask.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-01.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

class ResponseFutureTask<T> {
    open var taskIdentifier: Int
    open var future: ResponseFuture<T>
    open var error: Error?
    open var response: URLResponse?
    open var data: Data?
    open var urlRequest: URLRequest
    
    public init(taskIdentifier: Int, future: ResponseFuture<T>, urlRequest: URLRequest) {
        self.taskIdentifier = taskIdentifier
        self.future = future
        self.urlRequest = urlRequest
    }
}
