//
//  ThrottleIndicator.swift
//  RevEV4
//
//  Visual indicator for detected throttle position
//

import SwiftUI

/// Cyberpunk-styled throttle position indicator
struct ThrottleIndicator: View {
    /// Throttle position (0-1)
    let throttle: Double

    /// Current gear
    let gear: Int

    private var throttleColor: Color {
        if throttle > 0.7 {
            return CyberpunkTheme.neonRed
        } else if throttle > 0.3 {
            return CyberpunkTheme.neonYellow
        } else {
            return CyberpunkTheme.neonGreen
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Throttle bar
            VStack(alignment: .leading, spacing: 4) {
                Text("THROTTLE")
                    .font(.cyberpunkCaption)
                    .foregroundStyle(CyberpunkTheme.textMuted)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(CyberpunkTheme.surface)

                        // Fill
                        Capsule()
                            .fill(throttleColor)
                            .frame(width: max(4, geo.size.width * throttle))
                            .shadow(color: throttleColor.opacity(0.8), radius: 4)
                    }
                }
                .frame(height: 12)
            }

            // Gear indicator
            VStack(spacing: 2) {
                Text("GEAR")
                    .font(.cyberpunkCaption)
                    .foregroundStyle(CyberpunkTheme.textMuted)

                Text(gearDisplay)
                    .font(.cyberpunkGaugeSmall)
                    .foregroundStyle(CyberpunkTheme.neonCyan)
                    .shadow(color: CyberpunkTheme.neonCyan.opacity(0.8), radius: 4)
            }
            .frame(width: 50)
        }
        .padding()
        .cyberpunkCard()
    }

    private var gearDisplay: String {
        if gear == 0 {
            return "N"
        } else {
            return "\(gear)"
        }
    }
}

/// Compact throttle indicator for inline display
struct CompactThrottleIndicator: View {
    let throttle: Double

    private var throttleColor: Color {
        if throttle > 0.7 {
            return CyberpunkTheme.neonRed
        } else if throttle > 0.3 {
            return CyberpunkTheme.neonYellow
        } else {
            return CyberpunkTheme.neonGreen
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
            Text("\(Int(throttle * 100))%")
        }
        .font(.cyberpunkCaption)
        .foregroundStyle(throttleColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(CyberpunkTheme.cardBackground)
        .clipShape(Capsule())
    }
}

#Preview {
    ZStack {
        CyberpunkTheme.darkBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            ThrottleIndicator(throttle: 0.0, gear: 1)
            ThrottleIndicator(throttle: 0.5, gear: 3)
            ThrottleIndicator(throttle: 0.9, gear: 6)
            ThrottleIndicator(throttle: 0.2, gear: 0)

            HStack {
                CompactThrottleIndicator(throttle: 0.25)
                CompactThrottleIndicator(throttle: 0.75)
            }
        }
        .padding()
    }
}
