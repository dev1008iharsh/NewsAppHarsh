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

    // Callback to notify listeners (UI) about status changes
    var onStatusChange: ((Bool) -> Void)?

    private(set) var isConnected: Bool = false
    private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi, cellular, ethernet, unknown
    }

    private init() {
        monitor = NWPathMonitor()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            let newStatus = (path.status == .satisfied)
            
            // Update connection type
            self.getConnectionType(path)

            // Only notify if status actually changed or specifically needed
            // But usually, we just update state and notify.
            self.isConnected = newStatus
            
            // Notify listeners on Main Thread (since UI will likely update)
            DispatchQueue.main.async {
                self.onStatusChange?(self.isConnected)
            }

            print("🌐 Network Status: \(self.isConnected ? "Connected" : "Disconnected")")
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
