//
//  EnginePhysics.swift
//  RevEV4
//
//  Ported from engine-audio/src/Engine.ts
//  Physics-based engine simulation with inertia, torque curves, and limiter
//

import Foundation

/// Physics simulation for engine dynamics
final class EnginePhysics {
    // MARK: - Base Settings

    var idle: Double = 1000
    var limiter: Double = 9000
    var softLimiter: Double = 8950
    var rpm: Double = 1000

    // MARK: - Inertia

    /// Inertia of engine + clutch and flywheel [kg/m2]
    var inertia: Double = 1.0  // 0.5 * MR^2

    // MARK: - Limiter

    var limiterMs: Double = 0       // Hard cutoff time
    var limiterDelay: Double = 100  // Time while feeding throttle back in (ms)
    private var lastLimiter: Double = 0

    // MARK: - Torque Curves

    var torque: Double = 400        // Nm
    var engineBraking: Double = 200
    var throttle: Double = 0

    // MARK: - Integration State

    var theta: Double = 0       // Angular position (rad)
    var alpha: Double = 0       // Angular acceleration (rad/s^2)
    var omega: Double = 0       // Angular velocity (rad/s)

    var prevTheta: Double = 0
    var prevOmega: Double = 0
    var dTheta: Double = 0

    // MARK: - Precalculated Values

    var omegaMax: Double = 0

    // MARK: - Initialization

    init() {
        reset()
    }

    func reset() {
        omegaMax = (2 * .pi * limiter) / 60
        softLimiter = limiter * 0.99

        theta = 0
        alpha = 0
        omega = 0
        prevTheta = 0
        prevOmega = 0
        dTheta = 0
        rpm = idle
        lastLimiter = 0
    }

    func configure(config: EngineConfig) {
        limiter = config.limiter
        softLimiter = config.softLimiter
        limiterDelay = config.limiterDelay
        inertia = config.inertia
        reset()
    }

    // MARK: - Integration

    /// Main physics integration step
    /// - Parameters:
    ///   - loadInertia: Additional inertia from drivetrain
    ///   - time: Current simulation time (ms)
    ///   - dt: Time step (seconds)
    func integrate(loadInertia: Double, time: Double, dt: Double) {
        // Apply limiter
        if rpm >= softLimiter {
            let ratio = Self.ratio(rpm, softLimiter, limiter)
            throttle *= pow(1 - ratio, 0.05)
        }

        if rpm >= limiter {
            lastLimiter = time
        }

        if time - lastLimiter >= limiterMs {
            let t = time - lastLimiter
            let r = Self.ratio(t, 0, limiterDelay)
            throttle *= r
        } else {
            throttle = 0.0
        }

        // Idle adjustment - prevent stalling
        var idleTorque: Double = 0
        if throttle < 0.1 && rpm < idle * 1.5 {
            let rIdle = Self.ratio(rpm, idle * 0.9, idle)
            idleTorque = (1 - rIdle) * engineBraking * 10
        }

        // Calculate torque
        let t1 = pow(throttle, 1.2) * torque
        let t2 = pow(1 - throttle, 1.2) * engineBraking
        let netTorque = t1 - t2 + idleTorque

        // Integrate angular motion
        let I = loadInertia + inertia
        let dAlpha = netTorque / I

        prevTheta = theta
        omega += dAlpha * dt
        theta += omega * dt
        dTheta = omega * dt

        // Calculate RPM from angular velocity
        rpm = (60 * omega) / (2 * .pi)
    }

    /// Update step after constraint solving
    func update(h: Double) {
        prevOmega = omega
        let computedDTheta = (theta - prevTheta) / h
        omega = computedDTheta
    }

    // MARK: - Constraint Solving

    /// Position-based constraint with drivetrain
    func solvePos(drivetrain: DrivetrainPhysics, h: Double) {
        guard drivetrain.gear > 0 else { return }

        let compliance = max(0.0006 - 0.00015 * Double(drivetrain.gear), 0.00007)
        let c = drivetrain.theta - theta
        let corr = getCorrection(corr: c, h: h, compliance: compliance)
        theta += corr * (c >= 0 ? 1 : -1)
    }

    /// Velocity-based constraint with drivetrain
    func solveVel(drivetrain: DrivetrainPhysics, h: Double) {
        var damping: Double = 12
        if drivetrain.gear > 3 {
            damping = 9
        }
        omega += (drivetrain.omega - omega) * damping * h
    }

    private func getCorrection(corr: Double, h: Double, compliance: Double = 0) -> Double {
        let w = corr * corr * (1 / inertia)
        let dlambda = -corr / (w + compliance / h / h)
        return corr * -dlambda
    }

    // MARK: - Helper Functions

    /// Map value to 0-1 range
    static func ratio(_ value: Double, _ start: Double, _ end: Double) -> Double {
        return max(0, min(1, (value - start) / (end - start)))
    }

    /// Calculate pitch offset based on RPM difference from sample RPM
    func getRPMPitch(sampleRPM: Double, rpmPitchFactor: Double = 0.2) -> Double {
        return (rpm - sampleRPM) * rpmPitchFactor
    }
}
