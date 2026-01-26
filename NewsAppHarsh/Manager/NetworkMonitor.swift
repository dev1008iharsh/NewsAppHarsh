//
//  NetworkMonitor.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 01/02/24.
//

import Foundation
import Network
import SystemConfiguration

final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")

    private(set) var isConnected: Bool = false
    private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    private init() {
        monitor = NWPathMonitor()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            self.isConnected = (path.status == .satisfied)

            self.getConnectionType(path)

            print("🌐 Network Status: \(self.isConnected ? "Connected ✅" : "Disconnected ❌")")
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    private func getConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
}
