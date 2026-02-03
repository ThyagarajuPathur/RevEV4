//
//  DrivetrainPhysics.swift
//  RevEV4
//
//  Ported from engine-audio/src/Drivetrain.ts
//  Physics-based drivetrain simulation with gear ratios
//

import Foundation

/// Physics simulation for drivetrain (gearbox + driveshaft)
final class DrivetrainPhysics {
    // MARK: - Gear State

    var gear: Int = 0
    var clutch: Double = 1.0
    var downShift: Bool = false

    // MARK: - Gear Ratios

    var gears: [Double] = [3.4, 2.36, 1.85, 1.47, 1.24, 1.07]
    var finalDrive: Double = 3.44

    // MARK: - Integration State

    var theta: Double = 0       // Angular position (rad)
    var omega: Double = 0       // Angular velocity (rad/s)
    var prevTheta: Double = 0
    var prevOmega: Double = 0

    var thetaWheel: Double = 0
    var omegaWheel: Double = 0

    // MARK: - Physical Properties

    /// Inertia of geartrain + drive shaft [kg m2]
    var inertia: Double = 0.15  // 0.5 * MR^2
    var damping: Double = 12
    var compliance: Double = 0.01

    var shiftTime: Double = 50  // ms

    // MARK: - Shift Callback

    private var shiftWorkItem: DispatchWorkItem?

    // MARK: - Initialization

    init() {
        reset()
    }

    func reset() {
        theta = 0
        omega = 0
        prevTheta = 0
        prevOmega = 0
        thetaWheel = 0
        omegaWheel = 0
        gear = 0
    }

    func configure(shiftTime: Double, damping: Double) {
        self.shiftTime = shiftTime
        self.damping = damping
    }

    // MARK: - Integration

    func integrate(dt: Double) {
        clutch = max(0, min(1, clutch))
        prevTheta = theta
        theta += omega * dt
    }

    func update(h: Double) {
        prevOmega = omega
        let dTheta = (theta - prevTheta) / h
        omega = dTheta
    }

    // MARK: - Constraint Solving

    func solvePos(engine: EnginePhysics, h: Double) {
        let c = engine.theta - theta
        let corr = getCorrection(corr: c, h: h, compliance: compliance)
        theta += corr * (c >= 0 ? 1 : -1)
    }

    func solveVel(engine: EnginePhysics, h: Double) {
        var currentDamping = damping
        if gear > 3 {
            currentDamping = damping * 0.75
        }
        omega += (engine.omega - omega) * currentDamping * h
    }

    private func getCorrection(corr: Double, h: Double, compliance: Double = 0) -> Double {
        let w = corr * corr * (1 / inertia)
        let dlambda = -corr / (w + compliance / h / h)
        return corr * -dlambda
    }

    // MARK: - Gear Ratios

    func getFinalDriveRatio() -> Double {
        return finalDrive
    }

    func getGearRatio(for gear: Int? = nil) -> Double {
        let g = gear ?? self.gear
        let clampedGear = max(0, min(g, gears.count))

        return clampedGear > 0 ? gears[clampedGear - 1] : 0
    }

    func getTotalGearRatio() -> Double {
        return getGearRatio() * getFinalDriveRatio()
    }

    // MARK: - Gear Changes

    func changeGear(_ newGear: Int) {
        // Cancel any pending shift
        shiftWorkItem?.cancel()

        let prevRatio = getGearRatio(for: gear)
        let nextRatio = getGearRatio(for: newGear)
        let ratioRatio = prevRatio > 0 ? nextRatio / prevRatio : 0

        guard ratioRatio != 1 else { return }

        // Go to neutral
        gear = 0
        downShift = ratioRatio > 1

        // Engage next gear after shift time
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.omega = self.omega * ratioRatio
            self.gear = max(0, min(newGear, self.gears.count))
            self.downShift = false
            print("DEBUG: Changed to gear \(self.gear)")
        }

        shiftWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(shiftTime)), execute: workItem)
    }

    func nextGear() {
        changeGear(gear + 1)
    }

    func prevGear() {
        changeGear(gear - 1)
    }
}
