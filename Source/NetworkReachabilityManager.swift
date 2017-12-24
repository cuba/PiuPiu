//
//  NetworkReachabilityManager.swift
//  NetworkKit iOS
//
//  Created by Jacob Sikorski on 2017-12-23.
//  Copyright © 2017 Jacob Sikorski. All rights reserved.
//

import Alamofire

public typealias NetworkReachabilityCallback = (NetworkReachabilityStatus) -> Void

public enum NetworkReachabilityStatus {
    case unknown
    case notReachable
    case reachable
    
    init(_ status: Alamofire.NetworkReachabilityManager.NetworkReachabilityStatus) {
        switch status {
        case .notReachable: self = .notReachable
        case .reachable:    self = .reachable
        default:            self = .unknown
        }
    }
}

open class NetworkReachabilityManager {
    public static let shared = NetworkReachabilityManager()
    
    private let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.apple.com")
    private var callbacks: [NetworkReachabilityCallback?] = []
    
    public var isReachable: Bool {
        return reachabilityManager?.isReachable ?? false
    }
    
    public init() {
        reachabilityManager?.listener = { status in
            // Filter out nil callbacks
            self.callbacks = self.callbacks.flatMap({ return $0 })
            let newStatus = NetworkReachabilityStatus(status)
            self.callbacks.forEach({ $0?(newStatus) })
        }
    }
    
    public func callback(_ callback: @escaping NetworkReachabilityCallback) {
        // Filter out nil callbacks
        self.callbacks = self.callbacks.flatMap({ return $0 })
        self.callbacks.append(callback)
    }
    
    public func startListening() {
        reachabilityManager?.startListening()
    }
    
    public func stopListening() {
        reachabilityManager?.startListening()
    }
}
