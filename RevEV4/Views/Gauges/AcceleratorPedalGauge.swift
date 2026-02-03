//
//  AcceleratorPedalGauge.swift
//  RevEV4
//
//  Visual gauge for accelerator pedal position from VMCU
//

import SwiftUI

/// Cyberpunk-styled accelerator pedal gauge
struct AcceleratorPedalGauge: View {
    /// Pedal position (0-100%)
    let position: Int

    private var percentage: Double {
        min(1.0, Double(position) / 100.0)
    }

    private var gaugeColor: Color {
        if position > 80 {
            return CyberpunkTheme.neonRed
        } else if position > 50 {
            return CyberpunkTheme.neonOrange
        } else if position > 20 {
            return CyberpunkTheme.neonYellow
        } else {
            return CyberpunkTheme.neonGreen
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Title
            Text("ACCEL")
                .font(.cyberpunkCaption)
                .foregroundStyle(CyberpunkTheme.textSecondary)

            // Vertical bar gauge
            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(CyberpunkTheme.cardBackground)
                    .frame(width: 40, height: 120)

                // Fill
                RoundedRectangle(cornerRadius: 8)
                    .fill(gaugeColor)
                    .frame(width: 40, height: 120 * percentage)
                    .shadow(color: gaugeColor.opacity(0.8), radius: 4)
                    .shadow(color: gaugeColor.opacity(0.5), radius: 8)

                // Percentage text
                Text("\(position)%")
                    .font(.cyberpunkCaption)
                    .foregroundStyle(CyberpunkTheme.textPrimary)
                    .shadow(color: .black, radius: 2)
                    .padding(.bottom, 8)
            }

            // Pedal icon
            Image(systemName: "pedal.accelerator.fill")
                .font(.system(size: 20))
                .foregroundStyle(gaugeColor)
                .shadow(color: gaugeColor.opacity(0.8), radius: 4)
        }
        .padding()
        .cyberpunkCard()
    }
}

/// Horizontal accelerator bar (compact version)
struct AcceleratorBar: View {
    let position: Int

    private var percentage: Double {
        min(1.0, Double(position) / 100.0)
    }

    private var barColor: Color {
        if position > 80 {
            return CyberpunkTheme.neonRed
        } else if position > 50 {
            return CyberpunkTheme.neonOrange
        } else if position > 20 {
            return CyberpunkTheme.neonYellow
        } else {
            return CyberpunkTheme.neonGreen
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pedal.accelerator.fill")
                .foregroundStyle(barColor)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(CyberpunkTheme.surface)

                    // Fill
                    Capsule()
                        .fill(barColor)
                        .frame(width: max(4, geo.size.width * percentage))
                        .shadow(color: barColor.opacity(0.8), radius: 4)
                }
            }
            .frame(height: 16)

            Text("\(position)%")
                .font(.cyberpunkCaption)
                .foregroundStyle(barColor)
                .frame(width: 40, alignment: .trailing)
        }
        .padding()
        .cyberpunkCard()
    }
}

#Preview {
    ZStack {
        CyberpunkTheme.darkBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            HStack(spacing: 20) {
                AcceleratorPedalGauge(position: 0)
                AcceleratorPedalGauge(position: 25)
                AcceleratorPedalGauge(position: 60)
                AcceleratorPedalGauge(position: 100)
            }

            AcceleratorBar(position: 0)
            AcceleratorBar(position: 45)
            AcceleratorBar(position: 85)
        }
        .padding()
    }
}
