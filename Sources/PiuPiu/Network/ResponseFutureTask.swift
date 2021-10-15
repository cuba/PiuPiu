//
//  ResponseFutureTask.swift
//  PiuPiu iOS
//
//  Created by Jacob Sikorski on 2019-07-01.
//  Copyright © 2019 Jacob Sikorski. All rights reserved.
//

import Foundation

class ResponseFutureTask<Success> {
    let taskIdentifier: Int
    let future: ResponseFuture<Response<Success>>
    let destination: URL?
    var error: Error?
    var data: Data?
    
    
    public init(taskIdentifier: Int, future: ResponseFuture<Response<Success>>, destination: URL? = nil) {
        self.taskIdentifier = taskIdentifier
        self.future = future
        self.destination = destination
    }
}
