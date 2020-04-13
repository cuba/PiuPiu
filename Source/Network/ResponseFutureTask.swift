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
    open var future: ResponseFuture<Response<T>>
    open var error: Error?
    open var data: Data?
    
    public init(taskIdentifier: Int, future: ResponseFuture<Response<T>>) {
        self.taskIdentifier = taskIdentifier
        self.future = future
    }
}
