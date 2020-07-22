//
//  ResponseFutureTask.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-01.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

class ResponseFutureTask<T> {
    let taskIdentifier: Int
    let future: ResponseFuture<Response<T>>
    let destination: URL?
    var error: Error?
    var data: Data?
    
    
    public init(taskIdentifier: Int, future: ResponseFuture<Response<T>>, destination: URL? = nil) {
        self.taskIdentifier = taskIdentifier
        self.future = future
        self.destination = destination
    }
}
