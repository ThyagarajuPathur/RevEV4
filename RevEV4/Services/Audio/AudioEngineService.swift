//
//  AudioEngineService.swift
//  RevEV4
//
//  Physics-based audio engine with 4D crossfading:
//  RPM (low ↔ high) × Throttle (on ↔ off) × Limiter blend
//

import Foundation
import AVFoundation
import QuartzCore

/// Represents a loaded audio sample with player and varispeed nodes
private struct AudioPlayerNode {
    let sample: AudioSample
    let playerNode: AVAudioPlayerNode
    let varispeedNode: AVAudioUnitVarispeed
    let buffer: AVAudioPCMBuffer
}

/// Audio engine service for dynamic engine sound synthesis
@Observable
@MainActor
final class AudioEngineService {
    // MARK: - Published State

    private(set) var isPlaying = false
    private(set) var currentProfile: EngineProfile = .bacMono
    private(set) var currentPitch: Float = 0
    private(set) var volume: Float = 1.5

    // MARK: - Private Properties

    private var audioEngine: AVAudioEngine?

    // Sample players
    private var onLowPlayer: AudioPlayerNode?
    private var onHighPlayer: AudioPlayerNode?
    private var offLowPlayer: AudioPlayerNode?
    private var offHighPlayer: AudioPlayerNode?
    private var limiterPlayer: AudioPlayerNode?

    private var displayLink: CADisplayLink?
    private var targetRPM: Double = 800
    private var targetThrottle: Double = 0
    private var smoothedRPM: Double = 800
    private var smoothedThrottle: Double = 0

    // Crossfade parameters
    private let rpmCrossfadeStart: Double = 3000
    private let rpmCrossfadeEnd: Double = 6500
    private let rpmSmoothingFactor: Double = 0.15
    private let throttleSmoothingFactor: Double = 0.2

    // MARK: - Initialization

    init() {
        setupAudioSession()
    }

    // MARK: - Public Methods

    /// Load an engine profile and prepare all samples for playback
    func loadProfile(_ profile: EngineProfile) {
        currentProfile = profile

        // Reset players
        onLowPlayer = nil
        onHighPlayer = nil
        offLowPlayer = nil
        offHighPlayer = nil
        limiterPlayer = nil

        // Load each sample
        onLowPlayer = loadSample(profile.samples.onLow, label: "on_low")
        onHighPlayer = loadSample(profile.samples.onHigh, label: "on_high")
        offLowPlayer = loadSample(profile.samples.offLow, label: "off_low")
        offHighPlayer = loadSample(profile.samples.offHigh, label: "off_high")
        limiterPlayer = loadSample(profile.samples.limiter, label: "limiter")

        print("Loaded profile: \(profile.name)")
    }

    private func loadSample(_ sample: AudioSample, label: String) -> AudioPlayerNode? {
        guard let url = Bundle.main.url(forResource: sample.fileName, withExtension: "wav") else {
            print("Audio file not found: \(sample.fileName).wav")
            return nil
        }

        do {
            let audioFile = try AVAudioFile(forReading: url)
            let frameCount = AVAudioFrameCount(audioFile.length)

            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: audioFile.processingFormat,
                frameCapacity: frameCount
            ) else {
                print("Failed to create buffer for: \(sample.fileName)")
                return nil
            }

            try audioFile.read(into: buffer)

            let playerNode = AVAudioPlayerNode()
            let varispeedNode = AVAudioUnitVarispeed()

            print("Loaded sample: \(label) (\(sample.fileName)) @ \(sample.rpm) RPM")

            return AudioPlayerNode(
                sample: sample,
                playerNode: playerNode,
                varispeedNode: varispeedNode,
                buffer: buffer
            )
        } catch {
            print("Failed to load audio file \(sample.fileName): \(error)")
            return nil
        }
    }

    /// Start engine sound playback
    func start() {
        guard !isPlaying else { return }

        // Set initial idle RPM
        if targetRPM == 0 {
            targetRPM = 800
        }

        setupAudioEngine()
        startDisplayLink()
        isPlaying = true
    }

    /// Stop engine sound playback
    func stop() {
        isPlaying = false
        stopDisplayLink()

        // Stop all players
        let players = [onLowPlayer, onHighPlayer, offLowPlayer, offHighPlayer, limiterPlayer]
        for player in players {
            player?.playerNode.stop()
        }

        audioEngine?.stop()

        // Detach all nodes
        if let engine = audioEngine {
            for player in players {
                if let p = player {
                    engine.detach(p.playerNode)
                    engine.detach(p.varispeedNode)
                }
            }
        }

        audioEngine = nil
    }

    /// Update target RPM for pitch/crossfade calculation
    func updateRPM(_ rpm: Double) {
        targetRPM = max(800, rpm)
    }

    /// Update throttle position for crossfade
    func updateThrottle(_ throttle: Double) {
        targetThrottle = max(0, min(1, throttle))
    }

    /// Set playback volume
    func setVolume(_ volume: Float) {
        self.volume = max(0, min(2.0, volume))
    }

    /// Change engine profile
    func changeProfile(to profile: EngineProfile) {
        let wasPlaying = isPlaying

        if isPlaying {
            stop()
        }

        loadProfile(profile)

        if wasPlaying {
            start()
        }
    }

    // MARK: - Private Methods

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setPreferredIOBufferDuration(0.005)  // 5ms low latency
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }

        let players = [onLowPlayer, onHighPlayer, offLowPlayer, offHighPlayer, limiterPlayer]

        // Attach and connect all player nodes
        for player in players {
            guard let p = player else { continue }

            engine.attach(p.playerNode)
            engine.attach(p.varispeedNode)

            let format = p.buffer.format

            // Connect: Player -> Varispeed -> MainMixer
            engine.connect(p.playerNode, to: p.varispeedNode, format: format)
            engine.connect(p.varispeedNode, to: engine.mainMixerNode, format: format)

            // Initialize with zero volume
            p.playerNode.volume = 0
            p.varispeedNode.rate = 1.0
        }

        do {
            try engine.start()

            // Start all players looping
            for player in players {
                guard let p = player else { continue }
                p.playerNode.scheduleBuffer(p.buffer, at: nil, options: .loops)
                p.playerNode.play()
            }
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    private func startDisplayLink() {
        displayLink = CADisplayLink(target: DisplayLinkTarget(handler: { [weak self] in
            self?.tick()
        }), selector: #selector(DisplayLinkTarget.handleDisplayLink))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func tick() {
        // Smooth RPM transitions
        smoothedRPM += (targetRPM - smoothedRPM) * rpmSmoothingFactor
        smoothedThrottle += (targetThrottle - smoothedThrottle) * throttleSmoothingFactor

        // Apply sounds using 4D crossfade
        applySounds(rpm: smoothedRPM, throttle: smoothedThrottle)
    }

    /// Apply sounds using 4D crossfade: RPM × Throttle × Limiter
    private func applySounds(rpm: Double, throttle: Double) {
        // 1. RPM crossfade (low ↔ high)
        let (highGain, lowGain) = Self.crossFade(value: rpm, start: rpmCrossfadeStart, end: rpmCrossfadeEnd)

        // 2. Throttle crossfade (on ↔ off)
        let (onGain, offGain) = Self.crossFade(value: throttle, start: 0, end: 1)

        // 3. Limiter blend (starts at 93% of soft limiter)
        let limiterStart = currentProfile.config.softLimiter * 0.93
        let limiterGain = max(0, min(1, (rpm - limiterStart) / (currentProfile.config.limiter - limiterStart)))

        // Apply to each sample
        applyToPlayer(onLowPlayer, gain: onGain * lowGain, rpm: rpm)
        applyToPlayer(onHighPlayer, gain: onGain * highGain, rpm: rpm)
        applyToPlayer(offLowPlayer, gain: offGain * lowGain, rpm: rpm)
        applyToPlayer(offHighPlayer, gain: offGain * highGain, rpm: rpm)
        applyToPlayer(limiterPlayer, gain: Float(limiterGain), rpm: rpm, applyPitch: false)

        // Calculate weighted average pitch for display
        updateCurrentPitch()
    }

    private func applyToPlayer(_ player: AudioPlayerNode?, gain: Float, rpm: Double, applyPitch: Bool = true) {
        guard let player = player else { return }

        // Apply volume: crossfade gain * sample volume * master volume
        player.playerNode.volume = gain * Float(player.sample.volume) * volume

        // Apply pitch (detune based on rpm vs sample rpm)
        if applyPitch && player.sample.rpm > 0 {
            let rate = Float(rpm / player.sample.rpm)
            player.varispeedNode.rate = max(0.5, min(2.0, rate))
        }
    }

    private func updateCurrentPitch() {
        // Average pitch based on active samples
        var totalPitch: Float = 0
        var totalWeight: Float = 0

        let players = [onLowPlayer, onHighPlayer, offLowPlayer, offHighPlayer]
        for player in players {
            guard let p = player else { continue }
            let vol = p.playerNode.volume
            if vol > 0.01 {
                let pitch = 1200.0 * log2(p.varispeedNode.rate)
                totalPitch += pitch * vol
                totalWeight += vol
            }
        }

        currentPitch = totalWeight > 0 ? totalPitch / totalWeight : 0
    }

    // MARK: - Equal Power Crossfade

    /// Calculate equal-power crossfade gains
    /// - Parameters:
    ///   - value: Current value
    ///   - start: Value where gain1 is 0, gain2 is 1
    ///   - end: Value where gain1 is 1, gain2 is 0
    /// - Returns: Tuple of (gain1, gain2) that sum to ~1.0
    static func crossFade(value: Double, start: Double, end: Double) -> (Float, Float) {
        // Normalize to 0-1 range
        let x = max(0, min(1, (value - start) / (end - start)))

        // Equal power crossfade using cosine
        let gain1 = Float(cos((1.0 - x) * 0.5 * .pi))
        let gain2 = Float(cos(x * 0.5 * .pi))

        return (gain1, gain2)
    }
}

// MARK: - Display Link Helper

private class DisplayLinkTarget {
    let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    @objc func handleDisplayLink() {
        handler()
    }
}
