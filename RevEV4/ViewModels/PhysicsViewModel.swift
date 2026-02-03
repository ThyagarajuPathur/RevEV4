//
//  PhysicsViewModel.swift
//  RevEV4
//
//  ViewModel wrapper for VehicleSimulator physics
//

import Foundation
import Combine

/// ViewModel for physics simulation state
@Observable
@MainActor
final class PhysicsViewModel {
    // MARK: - Physics Simulator

    private let simulator: VehicleSimulator

    // MARK: - Published State

    /// Current simulated RPM
    var currentRPM: Double {
        simulator.currentRPM
    }

    /// Detected throttle position (0-1)
    var throttleState: Double {
        simulator.throttleState
    }

    /// Current gear
    var currentGear: Int {
        simulator.currentGear
    }

    // MARK: - Initialization

    init() {
        self.simulator = VehicleSimulator()
    }

    // MARK: - Configuration

    /// Configure physics for a specific engine profile
    func configure(profile: EngineProfile) {
        simulator.configure(profile: profile)
    }

    // MARK: - Updates

    /// Update simulation with target RPM from OBD
    /// - Parameters:
    ///   - targetRPM: Target RPM from OBD scanner
    ///   - dt: Time delta since last update (seconds)
    func update(targetRPM: Int, dt: Double) {
        simulator.update(targetRPM: targetRPM, dt: dt)
    }

    // MARK: - Throttle Detection

    /// Detect throttle from RPM rate of change
    /// - Parameters:
    ///   - currentRPM: Current RPM reading
    ///   - previousRPM: Previous RPM reading
    ///   - dt: Time delta (seconds)
    /// - Returns: Estimated throttle position (0-1)
    static func detectThrottle(currentRPM: Double, previousRPM: Double, dt: Double) -> Double {
        guard dt > 0 else { return 0.5 }

        let rpmChange = currentRPM - previousRPM
        let rpmRate = rpmChange / dt  // RPM per second

        // Map rate to throttle (0-1)
        // Positive rate = accelerating = throttle on
        // Negative rate = decelerating = throttle off
        let maxRate: Double = 2000  // RPM/sec at full throttle

        let throttle = max(0, min(1, (rpmRate + maxRate) / (2 * maxRate)))
        return throttle
    }
}
