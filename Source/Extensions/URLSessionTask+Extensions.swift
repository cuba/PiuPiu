//
//  URLSessionTask+Extensions.swift
//  PiuPiu
//
//  Created by Jakub Sikorski on 2020-07-25.
//  Copyright © 2020 Jacob Sikorski. All rights reserved.
//

import Foundation

public extension URLSessionTask {
    var safeCountOfBytesClientExpectsToReceive: Int64 {
        #if os(iOS)
        if #available(iOSApplicationExtension 11.0, *) {
            return countOfBytesClientExpectsToReceive
        } else {
            return countOfBytesExpectedToReceive
        }
        #elseif os(watchOS)
        if #available(watchOSApplicationExtension 4.0, *) {
            return countOfBytesClientExpectsToReceive
        } else {
            return countOfBytesExpectedToReceive
        }
        #elseif os(tvOS)
        if #available(tvOSApplicationExtension 11.0, *) {
            return countOfBytesClientExpectsToReceive
        } else {
            return countOfBytesExpectedToReceive
        }
        #elseif os(macOS)
        if #available(OSXApplicationExtension 10.13, *) {
            return countOfBytesClientExpectsToReceive
        } else {
            return countOfBytesExpectedToReceive
        }
        #endif
    }
    
    var safeCountOfBytesClientExpectsToSend: Int64 {
        #if os(iOS)
        if #available(iOSApplicationExtension 11.0, *) {
            return countOfBytesClientExpectsToSend
        } else {
            return countOfBytesExpectedToSend
        }
        #elseif os(watchOS)
        if #available(watchOSApplicationExtension 4.0, *) {
            return countOfBytesClientExpectsToSend
        } else {
            return countOfBytesExpectedToSend
        }
        #elseif os(tvOS)
        if #available(tvOSApplicationExtension 11.0, *) {
            return countOfBytesClientExpectsToSend
        } else {
            return countOfBytesExpectedToSend
        }
        #elseif os(macOS)
        if #available(OSXApplicationExtension 10.13, *) {
            return countOfBytesClientExpectsToSend
        } else {
            return countOfBytesExpectedToSend
        }
        #endif
    }
    
    var percentSent: Float? {
        let expectedToSend = safeCountOfBytesClientExpectsToSend
        
        if expectedToSend > 0 {
            return Float(Double(integerLiteral: countOfBytesSent) / Double(integerLiteral: expectedToSend))
        } else {
            return nil
        }
    }
    
    var percentRecieved: Float? {
        let expectedToReceive = safeCountOfBytesClientExpectsToReceive
        
        if expectedToReceive > 0 {
            return Float(Double(integerLiteral: countOfBytesReceived) / Double(integerLiteral: expectedToReceive))
        } else {
            return nil
        }
    }
    
    var percentTransferred: Float? {
        let expectedToSend = safeCountOfBytesClientExpectsToSend
        let expectedToReceive = safeCountOfBytesClientExpectsToReceive
        let expectedToTransfer = expectedToSend + expectedToReceive
        
        if expectedToTransfer > 0 {
            let dataTransferred = countOfBytesReceived + countOfBytesSent
            let progress = Float(Double(integerLiteral: dataTransferred) / Double(integerLiteral: expectedToTransfer))
            return progress
        } else {
            return nil
        }
    }
}
