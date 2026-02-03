//
//  AudioSample.swift
//  RevEV4
//
//  Represents a single audio sample with playback parameters
//

import Foundation

/// Audio sample definition for engine sound synthesis
struct AudioSample: Hashable, Sendable {
    /// File name without extension (looks for .wav in bundle)
    let fileName: String

    /// Reference RPM at which the sample was recorded
    /// Used for pitch calculation: rate = currentRPM / rpm
    let rpm: Double

    /// Base volume multiplier for this sample
    let volume: Double

    init(fileName: String, rpm: Double, volume: Double = 1.0) {
        self.fileName = fileName
        self.rpm = rpm
        self.volume = volume
    }
}

/// Collection of samples for a complete engine sound profile
struct EngineSamples: Hashable, Sendable {
    /// On-throttle low RPM sample
    let onLow: AudioSample

    /// On-throttle high RPM sample
    let onHigh: AudioSample

    /// Off-throttle (coasting) low RPM sample
    let offLow: AudioSample

    /// Off-throttle (coasting) high RPM sample
    let offHigh: AudioSample

    /// Rev limiter sample (plays at high RPM near redline)
    let limiter: AudioSample
}
