//
//  SpeedGaugeView.swift
//  RevEV4
//

import SwiftUI

/// Cyberpunk-styled speed gauge
struct SpeedGaugeView: View {
    let speed: Int
    let maxSpeed: Int

    private var percentage: Double {
        min(1.0, Double(speed) / Double(maxSpeed))
    }

    var body: some View {
        VStack(spacing: 8) {
            // Title
            Text("SPEED")
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

                // Value arc with gradient
                Circle()
                    .trim(from: 0.15, to: 0.15 + (0.7 * percentage))
                    .stroke(
                        CyberpunkTheme.neonMagenta,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                    .shadow(color: CyberpunkTheme.neonMagenta.opacity(0.8), radius: 4)
                    .shadow(color: CyberpunkTheme.neonMagenta.opacity(0.5), radius: 8)

                // Tick marks
                ForEach(0..<9) { index in
                    let angle = -135.0 + (Double(index) * 33.75)

                    Rectangle()
                        .fill(CyberpunkTheme.textMuted)
                        .frame(width: 2, height: index % 2 == 0 ? 12 : 6)
                        .offset(y: -55)
                        .rotationEffect(.degrees(angle))
                }

                // Center display
                VStack(spacing: 4) {
                    Text("\(speed)")
                        .font(.cyberpunkGauge)
                        .foregroundStyle(CyberpunkTheme.neonMagenta)
                        .shadow(color: CyberpunkTheme.neonMagenta.opacity(0.8), radius: 4)

                    Text("km/h")
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
            SpeedGaugeView(speed: 45, maxSpeed: 260)
            SpeedGaugeView(speed: 120, maxSpeed: 260)
            SpeedGaugeView(speed: 220, maxSpeed: 260)
        }
    }
}
