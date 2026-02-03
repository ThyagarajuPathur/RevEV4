//
//  DemoView.swift
//  RevEV4
//
//  Demo view with sliders to test audio without OBD connection
//

import SwiftUI

/// Demo view for testing engine audio with manual sliders
struct DemoView: View {
    @State var audioViewModel: AudioViewModel
    @Environment(\.dismiss) private var dismiss

    // Manual control values
    @State private var manualRPM: Double = 1000
    @State private var manualAccelerator: Double = 0

    init() {
        _audioViewModel = State(initialValue: AudioViewModel())
    }

    // For presenting from another view
    init(audioViewModel: AudioViewModel) {
        _audioViewModel = State(initialValue: audioViewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CyberpunkTheme.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Gauges
                        gaugesSection

                        // RPM Slider
                        rpmSliderSection

                        // Accelerator Slider
                        acceleratorSliderSection

                        // Quick presets
                        presetsSection

                        // Profile selector
                        profileSection

                        // Playback control
                        playbackSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Demo Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(CyberpunkTheme.neonCyan)
                }
            }
            .toolbarBackground(CyberpunkTheme.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                // Start audio if not playing
                if !audioViewModel.isPlaying {
                    audioViewModel.start()
                }
            }
        }
    }

    // MARK: - Gauges Section

    private var gaugesSection: some View {
        HStack(spacing: 16) {
            RPMGaugeView(
                rpm: Int(manualRPM),
                maxRPM: audioViewModel.currentProfile.maxRPM
            )

            AcceleratorPedalGauge(
                position: Int(manualAccelerator)
            )
        }
    }

    // MARK: - RPM Slider

    private var rpmSliderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RPM")
                    .font(.cyberpunkCaption)
                    .foregroundStyle(CyberpunkTheme.textMuted)

                Spacer()

                Text("\(Int(manualRPM))")
                    .font(.cyberpunkHeadline)
                    .foregroundStyle(rpmColor)
            }

            Slider(
                value: $manualRPM,
                in: 800...Double(audioViewModel.currentProfile.maxRPM),
                step: 100
            ) { editing in
                if !editing {
                    updateAudio()
                }
            }
            .tint(rpmColor)
            .onChange(of: manualRPM) { _, _ in
                updateAudio()
            }

            // RPM zone indicators
            HStack {
                Text("IDLE")
                    .font(.cyberpunkCaption)
                    .foregroundStyle(CyberpunkTheme.neonGreen)
                Spacer()
                Text("REDLINE")
                    .font(.cyberpunkCaption)
                    .foregroundStyle(CyberpunkTheme.neonRed)
            }
        }
        .padding()
        .cyberpunkCard()
    }

    private var rpmColor: Color {
        let percentage = manualRPM / Double(audioViewModel.currentProfile.maxRPM)
        if percentage > 0.85 {
            return CyberpunkTheme.neonRed
        } else if percentage > 0.6 {
            return CyberpunkTheme.neonYellow
        } else {
            return CyberpunkTheme.neonCyan
        }
    }

    // MARK: - Accelerator Slider

    private var acceleratorSliderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACCELERATOR PEDAL")
                    .font(.cyberpunkCaption)
                    .foregroundStyle(CyberpunkTheme.textMuted)

                Spacer()

                Text("\(Int(manualAccelerator))%")
                    .font(.cyberpunkHeadline)
                    .foregroundStyle(acceleratorColor)
            }

            Slider(
                value: $manualAccelerator,
                in: 0...100,
                step: 1
            ) { editing in
                if !editing {
                    updateAudio()
                }
            }
            .tint(acceleratorColor)
            .onChange(of: manualAccelerator) { _, _ in
                updateAudio()
            }

            // Throttle zone indicators
            HStack {
                Text("COAST")
                    .font(.cyberpunkCaption)
                    .foregroundStyle(CyberpunkTheme.neonGreen)
                Spacer()
                Text("FULL THROTTLE")
                    .font(.cyberpunkCaption)
                    .foregroundStyle(CyberpunkTheme.neonRed)
            }
        }
        .padding()
        .cyberpunkCard()
    }

    private var acceleratorColor: Color {
        if manualAccelerator > 80 {
            return CyberpunkTheme.neonRed
        } else if manualAccelerator > 50 {
            return CyberpunkTheme.neonOrange
        } else if manualAccelerator > 20 {
            return CyberpunkTheme.neonYellow
        } else {
            return CyberpunkTheme.neonGreen
        }
    }

    // MARK: - Presets Section

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK PRESETS")
                .font(.cyberpunkCaption)
                .foregroundStyle(CyberpunkTheme.textMuted)

            HStack(spacing: 12) {
                PresetButton(title: "Idle", icon: "pause.fill") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        manualRPM = 800
                        manualAccelerator = 0
                    }
                }

                PresetButton(title: "Cruise", icon: "car.fill") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        manualRPM = 3000
                        manualAccelerator = 30
                    }
                }

                PresetButton(title: "Accelerate", icon: "arrow.up.right") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        manualRPM = 5500
                        manualAccelerator = 75
                    }
                }

                PresetButton(title: "Redline", icon: "flame.fill") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        manualRPM = Double(audioViewModel.currentProfile.maxRPM) - 200
                        manualAccelerator = 100
                    }
                }
            }
        }
        .padding()
        .cyberpunkCard()
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ENGINE PROFILE")
                .font(.cyberpunkCaption)
                .foregroundStyle(CyberpunkTheme.textMuted)

            HStack(spacing: 12) {
                ForEach(audioViewModel.availableProfiles) { profile in
                    ProfileButton(
                        name: profile.name,
                        isSelected: profile.id == audioViewModel.currentProfile.id
                    ) {
                        audioViewModel.selectProfile(profile)
                        // Clamp RPM to new profile's max
                        if manualRPM > Double(profile.maxRPM) {
                            manualRPM = Double(profile.maxRPM) - 200
                        }
                    }
                }
            }
        }
        .padding()
        .cyberpunkCard()
    }

    // MARK: - Playback Section

    private var playbackSection: some View {
        VStack(spacing: 16) {
            // Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("STATUS")
                        .font(.cyberpunkCaption)
                        .foregroundStyle(CyberpunkTheme.textMuted)

                    HStack(spacing: 16) {
                        Label("Throttle: \(Int(audioViewModel.throttleState * 100))%", systemImage: "gauge")
                        Label("Gear: \(audioViewModel.currentGear == 0 ? "N" : "\(audioViewModel.currentGear)")", systemImage: "gearshape")
                        Label("Pitch: \(Int(audioViewModel.currentPitch))¢", systemImage: "waveform")
                    }
                    .font(.cyberpunkCaption)
                    .foregroundStyle(CyberpunkTheme.neonCyan)
                }
                Spacer()
            }

            // Play/Stop button
            Button {
                audioViewModel.togglePlayback()
            } label: {
                HStack {
                    Image(systemName: audioViewModel.isPlaying ? "stop.fill" : "play.fill")
                    Text(audioViewModel.isPlaying ? "Stop Engine" : "Start Engine")
                }
                .font(.cyberpunkBody)
                .foregroundStyle(CyberpunkTheme.darkBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(audioViewModel.isPlaying ? CyberpunkTheme.neonRed : CyberpunkTheme.neonGreen)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: (audioViewModel.isPlaying ? CyberpunkTheme.neonRed : CyberpunkTheme.neonGreen).opacity(0.5), radius: 8)
            }
        }
        .padding()
        .cyberpunkCard()
    }

    // MARK: - Audio Update

    private func updateAudio() {
        audioViewModel.updateFromOBD(
            rpm: Int(manualRPM),
            acceleratorPedal: Int(manualAccelerator)
        )
    }
}

// MARK: - Helper Views

struct PresetButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.cyberpunkCaption)
            }
            .foregroundStyle(CyberpunkTheme.neonCyan)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(CyberpunkTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(CyberpunkTheme.neonCyan.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct ProfileButton: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.cyberpunkCaption)
                .foregroundStyle(isSelected ? CyberpunkTheme.darkBackground : CyberpunkTheme.neonMagenta)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? CyberpunkTheme.neonMagenta : CyberpunkTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(CyberpunkTheme.neonMagenta.opacity(isSelected ? 1 : 0.3), lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}

#Preview {
    DemoView()
}
