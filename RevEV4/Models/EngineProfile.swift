//
//  EngineProfile.swift
//  RevEV4
//
//  Engine sound profile with 5 samples and physics configuration
//

import Foundation

/// Engine sound profile configuration
struct EngineProfile: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String
    let samples: EngineSamples
    let config: EngineConfig

    /// Maximum displayable RPM for gauges
    var maxRPM: Int {
        Int(config.limiter) + 100
    }

    // MARK: - Predefined Profiles

    /// BAC Mono - High-revving naturally aspirated
    static let bacMono = EngineProfile(
        id: "bac_mono",
        name: "BAC Mono",
        description: "High-revving naturally aspirated screamer",
        samples: EngineSamples(
            onLow: AudioSample(fileName: "BAC_Mono_onlow", rpm: 1000, volume: 0.5),
            onHigh: AudioSample(fileName: "BAC_Mono_onhigh", rpm: 1000, volume: 0.5),
            offLow: AudioSample(fileName: "BAC_Mono_offlow", rpm: 1000, volume: 0.5),
            offHigh: AudioSample(fileName: "BAC_Mono_offveryhigh", rpm: 1000, volume: 0.5),
            limiter: AudioSample(fileName: "limiter", rpm: 8000, volume: 0.4)
        ),
        config: EngineConfig(
            limiter: 9000,
            softLimiter: 8950,
            limiterDelay: 0,
            inertia: 1.0,
            shiftTime: 50,
            damping: 16
        )
    )

    /// Ferrari 458 - V8 mid-engine exotic
    static let ferrari458 = EngineProfile(
        id: "ferrari_458",
        name: "Ferrari 458",
        description: "Italian V8 exotic with flat-plane crank",
        samples: EngineSamples(
            onLow: AudioSample(fileName: "458_mid_res_2", rpm: 5300, volume: 1.5),
            onHigh: AudioSample(fileName: "458_power_2", rpm: 7700, volume: 2.5),
            offLow: AudioSample(fileName: "458_off_midhigh", rpm: 6900, volume: 1.4),
            offHigh: AudioSample(fileName: "458_off_higher", rpm: 7900, volume: 1.6),
            limiter: AudioSample(fileName: "458_limiter", rpm: 8500, volume: 1.8)
        ),
        config: EngineConfig(
            limiter: 8900,
            softLimiter: 8800,
            limiterDelay: 0,
            inertia: 0.8,
            shiftTime: 10,
            damping: 6
        )
    )

    /// Porsche 962 - Classic turbo flat-6 race car
    static let porsche962 = EngineProfile(
        id: "porsche_962",
        name: "Porsche 962",
        description: "Classic Group C turbo flat-6",
        samples: EngineSamples(
            onLow: AudioSample(fileName: "procar_on_low", rpm: 3200, volume: 1.0),
            onHigh: AudioSample(fileName: "procar_on_midhigh", rpm: 8000, volume: 1.0),
            offLow: AudioSample(fileName: "procar_off_lower", rpm: 3400, volume: 1.3),
            offHigh: AudioSample(fileName: "procar_off_midhigh", rpm: 8430, volume: 1.3),
            limiter: AudioSample(fileName: "limiter", rpm: 8000, volume: 0.5)
        ),
        config: EngineConfig(
            limiter: 9000,
            softLimiter: 9000,
            limiterDelay: 150,
            inertia: 1.0,
            shiftTime: 100,
            damping: 12
        )
    )

    /// All available profiles
    static let allProfiles: [EngineProfile] = [
        .bacMono,
        .ferrari458,
        .porsche962
    ]
}
