//
//  EngineConfig.swift
//  RevEV4
//
//  Physics configuration for engine profiles
//

import Foundation

/// Physics configuration for an engine profile
struct EngineConfig: Hashable, Sendable {
    /// Hard RPM limiter (engine cuts above this)
    let limiter: Double

    /// Soft RPM limiter (throttle starts reducing)
    let softLimiter: Double

    /// Recovery delay after hitting limiter (ms)
    let limiterDelay: Double

    /// Engine rotational inertia [kg/m2]
    let inertia: Double

    /// Gear shift time (ms)
    let shiftTime: Double

    /// Drivetrain damping factor
    let damping: Double

    init(
        limiter: Double,
        softLimiter: Double? = nil,
        limiterDelay: Double = 100,
        inertia: Double = 1.0,
        shiftTime: Double = 50,
        damping: Double = 12
    ) {
        self.limiter = limiter
        self.softLimiter = softLimiter ?? (limiter * 0.99)
        self.limiterDelay = limiterDelay
        self.inertia = inertia
        self.shiftTime = shiftTime
        self.damping = damping
    }
}
