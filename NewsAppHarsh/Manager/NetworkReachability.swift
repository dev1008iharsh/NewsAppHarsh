//
//  NetworkReachability.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 01/02/24.
//

import Foundation
import SystemConfiguration

class NetworkReachability {
    
    static let shared = NetworkReachability()
    
    private let reachability = SCNetworkReachabilityCreateWithName(nil, "www.apple.com")!
    
    func isNetworkAvailable() -> Bool {
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability, &flags)
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
}
