//
//  RPMGaugeView.swift
//  RevEV4
//

import SwiftUI

/// Cyberpunk-styled RPM gauge
struct RPMGaugeView: View {
    let rpm: Int
    let maxRPM: Int

    private var percentage: Double {
        min(1.0, Double(abs(rpm)) / Double(maxRPM))
    }

    private var gaugeColor: Color {
        if percentage < 0.6 {
            return CyberpunkTheme.neonCyan
        } else if percentage < 0.8 {
            return CyberpunkTheme.neonYellow
        } else {
            return CyberpunkTheme.neonRed
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Title
            Text("RPM")
                .font(.cyberpunkCaption)
                .foregroundStyle(CyberpunkTheme.textSecondary)

            // Gauge
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0.15, to: 0.85)
                    .stroke(
                        CyberpunkTheme.cardBackground,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))

                // Value arc
                Circle()
                    .trim(from: 0.15, to: 0.15 + (0.7 * percentage))
                    .stroke(
                        gaugeColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                    .shadow(color: gaugeColor.opacity(0.8), radius: 4)
                    .shadow(color: gaugeColor.opacity(0.5), radius: 8)

                // Tick marks
                ForEach(0..<9) { index in
                    let angle = -135.0 + (Double(index) * 33.75)
                    let isRedZone = index >= 7

                    Rectangle()
                        .fill(isRedZone ? CyberpunkTheme.neonRed : CyberpunkTheme.textMuted)
                        .frame(width: 2, height: index % 2 == 0 ? 12 : 6)
                        .offset(y: -55)
                        .rotationEffect(.degrees(angle))
                }

                // Center display
                VStack(spacing: 4) {
                    Text("\(abs(rpm))")
                        .font(.cyberpunkGauge)
                        .foregroundStyle(gaugeColor)
                        .shadow(color: gaugeColor.opacity(0.8), radius: 4)

                    Text("RPM")
                        .font(.cyberpunkCaption)
                        .foregroundStyle(CyberpunkTheme.textMuted)
                }
            }
            .frame(width: 160, height: 160)
        }
        .padding()
        .cyberpunkCard()
    }
}

#Preview {
    ZStack {
        CyberpunkTheme.darkBackground.ignoresSafeArea()

        HStack(spacing: 20) {
            RPMGaugeView(rpm: 0, maxRPM: 10100)
            RPMGaugeView(rpm: 5000, maxRPM: 10100)
            RPMGaugeView(rpm: 8500, maxRPM: 10100)
        }
    }
}
