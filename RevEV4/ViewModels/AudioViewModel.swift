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

    /// Current throttle state (0-1) from real accelerator pedal
    private(set) var throttleState: Double = 0

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

    // MARK: - OBD Data Updates

    /// Update from OBD data (RPM and real accelerator pedal)
    func updateFromOBD(rpm: Int, acceleratorPedal: Int) {
        let now = Date()
        let dt = now.timeIntervalSince(lastUpdateTime)
        lastUpdateTime = now

        // Update physics simulation
        if dt > 0 && dt < 1.0 {
            vehicleSimulator.update(targetRPM: rpm, dt: dt)
        }

        // Use REAL accelerator pedal position (0-100% -> 0-1)
        throttleState = Double(acceleratorPedal) / 100.0

        // Update audio engine with RPM and REAL throttle
        audioService.updateRPM(Double(abs(rpm)))
        audioService.updateThrottle(throttleState)

        previousRPM = rpm
    }

    /// Legacy method - updates RPM only (throttle will be 0)
    func updateRPM(_ rpm: Int) {
        updateFromOBD(rpm: rpm, acceleratorPedal: 0)
    }

    // MARK: - Profile Management

    func selectProfile(_ profile: EngineProfile) {
        audioService.changeProfile(to: profile)
        vehicleSimulator.configure(profile: profile)
    }
}
