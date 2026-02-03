//
//  EngineSelectorView.swift
//  RevEV4
//
//  View for selecting engine sound profiles
//

import SwiftUI

/// View for selecting engine sound profiles
struct EngineSelectorView: View {
    @Bindable var viewModel: AudioViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                CyberpunkTheme.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Volume control
                        VStack(alignment: .leading, spacing: 12) {
                            Text("VOLUME")
                                .font(.cyberpunkCaption)
                                .foregroundStyle(CyberpunkTheme.textMuted)

                            HStack(spacing: 16) {
                                Image(systemName: "speaker.fill")
                                    .foregroundStyle(CyberpunkTheme.textSecondary)

                                Slider(value: Binding(
                                    get: { Double(viewModel.volume) },
                                    set: { viewModel.volume = Float($0) }
                                ))
                                .tint(CyberpunkTheme.neonCyan)

                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundStyle(CyberpunkTheme.textSecondary)
                            }
                        }
                        .padding()
                        .cyberpunkCard()

                        // Current status
                        if viewModel.isPlaying {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("STATUS")
                                        .font(.cyberpunkCaption)
                                        .foregroundStyle(CyberpunkTheme.textMuted)

                                    HStack(spacing: 12) {
                                        Label("Throttle: \(Int(viewModel.throttleState * 100))%", systemImage: "gauge")
                                        Label("Gear: \(viewModel.currentGear == 0 ? "N" : "\(viewModel.currentGear)")", systemImage: "gearshape")
                                    }
                                    .font(.cyberpunkCaption)
                                    .foregroundStyle(CyberpunkTheme.neonCyan)
                                }
                                Spacer()
                            }
                            .padding()
                            .cyberpunkCard()
                        }

                        // Engine profiles
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ENGINE SOUND")
                                .font(.cyberpunkCaption)
                                .foregroundStyle(CyberpunkTheme.textMuted)
                                .padding(.horizontal)

                            ForEach(viewModel.availableProfiles) { profile in
                                EngineProfileRow(
                                    profile: profile,
                                    isSelected: profile.id == viewModel.currentProfile.id
                                ) {
                                    viewModel.selectProfile(profile)
                                }
                            }
                        }

                        // Playback control
                        Button {
                            viewModel.togglePlayback()
                        } label: {
                            HStack {
                                Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                                Text(viewModel.isPlaying ? "Stop Engine Sound" : "Start Engine Sound")
                            }
                            .font(.cyberpunkBody)
                            .foregroundStyle(CyberpunkTheme.darkBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(viewModel.isPlaying ? CyberpunkTheme.neonRed : CyberpunkTheme.neonGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: (viewModel.isPlaying ? CyberpunkTheme.neonRed : CyberpunkTheme.neonGreen).opacity(0.5), radius: 8)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Engine Sound")
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
        }
    }
}

struct EngineProfileRow: View {
    let profile: EngineProfile
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? CyberpunkTheme.neonMagenta.opacity(0.2) : CyberpunkTheme.cardBackground)
                        .frame(width: 50, height: 50)

                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? CyberpunkTheme.neonMagenta : CyberpunkTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.cyberpunkBody)
                        .foregroundStyle(isSelected ? CyberpunkTheme.neonMagenta : CyberpunkTheme.textPrimary)

                    Text(profile.description)
                        .font(.cyberpunkCaption)
                        .foregroundStyle(CyberpunkTheme.textMuted)

                    // Config info
                    Text("Redline: \(Int(profile.config.limiter)) RPM")
                        .font(.cyberpunkCaption)
                        .foregroundStyle(CyberpunkTheme.neonRed.opacity(0.7))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(CyberpunkTheme.neonMagenta)
                }
            }
            .padding()
            .background(isSelected ? CyberpunkTheme.neonMagenta.opacity(0.1) : CyberpunkTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? CyberpunkTheme.neonMagenta : CyberpunkTheme.textMuted.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .padding(.horizontal)
    }

    private var iconName: String {
        switch profile.id {
        case "bac_mono":
            return "bolt.car.fill"
        case "ferrari_458":
            return "car.fill"
        case "porsche_962":
            return "flag.checkered"
        default:
            return "waveform"
        }
    }
}

#Preview {
    EngineSelectorView(viewModel: AudioViewModel())
}
