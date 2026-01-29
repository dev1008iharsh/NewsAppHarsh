//
//  NetworkMonitor.swift
//  NewsAppHarsh
//
//  Created by My Mac Mini on 01/02/24.
//

import Network

final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")

    // Prevent duplicate start
    private var isMonitoringStarted = false

    // Callback to notify listeners
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
        guard !isMonitoringStarted else { return }
        isMonitoringStarted = true

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            let newStatus = path.status == .satisfied
            self.getConnectionType(path)
            self.isConnected = newStatus

            DispatchQueue.main.async {
                self.onStatusChange?(newStatus)
            }
        }

        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
        isMonitoringStarted = false
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
