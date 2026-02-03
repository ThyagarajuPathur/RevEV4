//
//  AudioViewModel.swift
//  RevEV4
//
//  ViewModel for audio engine control with physics integration
//

import Foundation
import Combine

/// ViewModel for audio engine control
@Observable
@MainActor
final class AudioViewModel {
    // MARK: - Services

    private let audioService: AudioEngineService
    private let vehicleSimulator: VehicleSimulator

    // MARK: - State

    var isPlaying: Bool {
        audioService.isPlaying
    }

    var currentProfile: EngineProfile {
        audioService.currentProfile
    }

    var currentPitch: Float {
        audioService.currentPitch
    }

    var volume: Float {
        get { audioService.volume }
        set { audioService.setVolume(newValue) }
    }

    var availableProfiles: [EngineProfile] {
        EngineProfile.allProfiles
    }

    /// Current throttle state (0-1) detected from RPM changes
    var throttleState: Double {
        vehicleSimulator.throttleState
    }

    /// Current gear from physics simulation
    var currentGear: Int {
        vehicleSimulator.currentGear
    }

    // MARK: - Private State

    private var previousRPM: Int = 0
    private var lastUpdateTime: Date = Date()

    // MARK: - Initialization

    init() {
        self.audioService = AudioEngineService()
        self.vehicleSimulator = VehicleSimulator()

        // Load BAC Mono profile by default
        audioService.loadProfile(.bacMono)
        vehicleSimulator.configure(profile: .bacMono)
    }

    // MARK: - Playback Control

    func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    func start() {
        audioService.start()
    }

    func stop() {
        audioService.stop()
    }

    // MARK: - RPM Updates

    func updateRPM(_ rpm: Int) {
        let now = Date()
        let dt = now.timeIntervalSince(lastUpdateTime)
        lastUpdateTime = now

        // Update physics simulation
        if dt > 0 && dt < 1.0 {  // Sanity check for time delta
            vehicleSimulator.update(targetRPM: rpm, dt: dt)
        }

        // Update audio engine with RPM and detected throttle
        audioService.updateRPM(Double(abs(rpm)))
        audioService.updateThrottle(vehicleSimulator.throttleState)

        previousRPM = rpm
    }

    // MARK: - Profile Management

    func selectProfile(_ profile: EngineProfile) {
        audioService.changeProfile(to: profile)
        vehicleSimulator.configure(profile: profile)
    }
}
