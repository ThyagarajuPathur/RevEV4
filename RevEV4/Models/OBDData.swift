//
//  OBDData.swift
//  RevEV4
//

import Foundation

/// Real-time OBD-II data from the vehicle
struct OBDData: Sendable {
    var rpm: Int = 0
    var speed: Int = 0
    var timestamp: Date = Date()

    /// RPM as a percentage (0.0 to 1.0) based on typical range 0-8000
    var rpmPercentage: Double {
        min(1.0, max(0.0, Double(rpm) / 8000.0))
    }

    /// Speed as a percentage (0.0 to 1.0) based on 0-260 km/h
    var speedPercentage: Double {
        min(1.0, max(0.0, Double(speed) / 260.0))
    }
}

/// Raw OBD command and response for debugging
struct OBDTransaction: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let command: String
    let response: String
    let isError: Bool

    init(command: String, response: String, isError: Bool = false) {
        self.timestamp = Date()
        self.command = command
        self.response = response
        self.isError = isError
    }
}

/// OBD-II PIDs used in this app
enum OBDPid: String, Sendable {
    case rpm = "010C"
    case speed = "010D"

    var description: String {
        switch self {
        case .rpm: return "Engine RPM"
        case .speed: return "Vehicle Speed"
        }
    }
}
