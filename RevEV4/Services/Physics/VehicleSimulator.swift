//
//  VehicleSimulator.swift
//  RevEV4
//
//  Ported from engine-audio/src/Vehicle.ts
//  Orchestrates engine and drivetrain physics simulation
//

import Foundation
import Combine

/// Main vehicle simulator that orchestrates physics
@Observable
@MainActor
final class VehicleSimulator {
    // MARK: - Physics Components

    let engine = EnginePhysics()
    let drivetrain = DrivetrainPhysics()

    // MARK: - Published State

    private(set) var currentRPM: Double = 1000
    private(set) var throttleState: Double = 0
    private(set) var currentGear: Int = 1

    // MARK: - Vehicle Properties

    var mass: Double = 500
    var velocity: Double = 0
    var wheelRPM: Double = 0
    var wheelOmega: Double = 0
    var wheelRadius: Double = 0.250

    // MARK: - Throttle Detection

    private var previousRPM: Double = 1000
    private var smoothedThrottle: Double = 0
    private let throttleSmoothingFactor: Double = 0.15

    // MARK: - Configuration

    func configure(profile: EngineProfile) {
        engine.configure(config: profile.config)
        drivetrain.configure(
            shiftTime: profile.config.shiftTime,
            damping: profile.config.damping
        )

        // Start in first gear
        drivetrain.gear = 1
        currentGear = 1
    }

    // MARK: - Simulation

    /// Update simulation with target RPM from OBD
    /// - Parameters:
    ///   - targetRPM: Target RPM from OBD scanner
    ///   - dt: Time delta in seconds
    func update(targetRPM: Int, dt: Double) {
        let targetRPMDouble = Double(abs(targetRPM))

        // Detect throttle from RPM rate of change
        detectThrottle(currentRPM: targetRPMDouble, dt: dt)

        // Auto-shift based on RPM
        autoShift(rpm: targetRPMDouble)

        // Run physics sub-steps
        let subSteps = 20
        let h = dt / Double(subSteps)
        let loadInertia = getLoadInertia() * 0.00  // Minimal load for responsiveness

        // Set engine throttle from detected value
        engine.throttle = smoothedThrottle

        for i in 0..<subSteps {
            let time = Double(i) * h * 1000  // Convert to ms

            engine.integrate(loadInertia: loadInertia, time: time, dt: h)
            drivetrain.integrate(dt: h)

            engine.solvePos(drivetrain: drivetrain, h: h)
            drivetrain.solvePos(engine: engine, h: h)

            engine.update(h: h)
            drivetrain.update(h: h)

            engine.solveVel(drivetrain: drivetrain, h: h)
            drivetrain.solveVel(engine: engine, h: h)
        }

        // Blend simulated RPM with target for responsiveness
        // Use target RPM directly but let physics influence throttle detection
        currentRPM = targetRPMDouble
        previousRPM = targetRPMDouble
        currentGear = drivetrain.gear
    }

    // MARK: - Throttle Detection

    /// Detect throttle position from RPM rate of change
    private func detectThrottle(currentRPM: Double, dt: Double) {
        guard dt > 0 else { return }

        let rpmChange = currentRPM - previousRPM
        let rpmRate = rpmChange / dt  // RPM per second

        // Map rate to throttle (0-1)
        // Positive rate = accelerating = throttle on
        // Negative rate = decelerating = throttle off
        let maxRate: Double = 2000  // RPM/sec at full throttle

        // Calculate raw throttle from rate
        let rawThrottle = max(0, min(1, (rpmRate + maxRate) / (2 * maxRate)))

        // Smooth with exponential filter
        smoothedThrottle = smoothedThrottle * (1 - throttleSmoothingFactor) + rawThrottle * throttleSmoothingFactor

        // Update published throttle state
        throttleState = smoothedThrottle
    }

    // MARK: - Auto-Shifting

    private func autoShift(rpm: Double) {
        let upshiftRPM = engine.limiter * 0.85
        let downshiftRPM = engine.idle * 2.5

        if rpm > upshiftRPM && drivetrain.gear < drivetrain.gears.count {
            drivetrain.nextGear()
        } else if rpm < downshiftRPM && drivetrain.gear > 1 {
            drivetrain.prevGear()
        }
    }

    // MARK: - Load Inertia

    func getLoadInertia() -> Double {
        guard drivetrain.gear > 0 else { return 0 }

        let gearRatio = drivetrain.getGearRatio()
        let totalGearRatio = drivetrain.getTotalGearRatio()

        // Moment of inertia - I = mr^2
        let iVeh = mass * pow(wheelRadius, 2)
        let iWheels = 4 * 12.0 * pow(wheelRadius, 2)

        // Adjust inertia for gear ratio
        let i1 = iVeh / pow(totalGearRatio, 2)
        let i2 = iWheels / pow(totalGearRatio, 2)
        let i3 = drivetrain.inertia / pow(gearRatio, 2)

        return i1 + i2 + i3
    }
}
