//
//  ConnectionState.swift
//  RevEV4
//

import Foundation

/// Represents the current connection state of the OBD adapter
enum ConnectionState: Equatable, Sendable {
    case disconnected
    case scanning
    case connecting
    case connected
    case initializing
    case ready
    case error(String)

    var displayText: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .scanning:
            return "Scanning..."
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .initializing:
            return "Initializing..."
        case .ready:
            return "Ready"
        case .error(let message):
            return "Error: \(message)"
        }
    }

    var isConnected: Bool {
        switch self {
        case .connected, .initializing, .ready:
            return true
        default:
            return false
        }
    }
}
