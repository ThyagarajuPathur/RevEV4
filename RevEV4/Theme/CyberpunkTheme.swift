//
//  CyberpunkTheme.swift
//  RevEV4
//

import SwiftUI

/// Cyberpunk theme colors and styles
enum CyberpunkTheme {
    // MARK: - Primary Colors

    static let neonCyan = Color(hex: "00FFFF")
    static let neonMagenta = Color(hex: "FF00FF")
    static let neonPink = Color(hex: "FF0080")
    static let neonGreen = Color(hex: "00FF80")
    static let neonYellow = Color(hex: "FFFF00")
    static let neonOrange = Color(hex: "FF8000")
    static let neonRed = Color(hex: "FF0040")

    // MARK: - Background Colors

    static let darkBackground = Color(hex: "0D0D1A")
    static let cardBackground = Color(hex: "1A1A2E")
    static let surfaceBackground = Color(hex: "16213E")
    static let surface = Color(hex: "1A1A2E")

    // MARK: - Text Colors

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textMuted = Color.white.opacity(0.4)

    // MARK: - Gradients

    static let cyanMagentaGradient = LinearGradient(
        colors: [neonCyan, neonMagenta],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let rpmGaugeGradient = LinearGradient(
        colors: [neonCyan, neonGreen, neonYellow, neonOrange, neonRed],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let glowGradient = RadialGradient(
        colors: [neonCyan.opacity(0.6), neonCyan.opacity(0)],
        center: .center,
        startRadius: 0,
        endRadius: 100
    )

    // MARK: - Shadows

    static func neonGlow(color: Color = neonCyan, radius: CGFloat = 10) -> some View {
        Rectangle()
            .fill(.clear)
            .shadow(color: color.opacity(0.8), radius: radius)
            .shadow(color: color.opacity(0.5), radius: radius * 2)
    }

    // MARK: - Modifiers

    static func cardStyle() -> some ViewModifier {
        CardStyleModifier()
    }

    static func glowingBorder(color: Color = neonCyan, lineWidth: CGFloat = 2) -> some ViewModifier {
        GlowingBorderModifier(color: color, lineWidth: lineWidth)
    }
}

// MARK: - View Modifiers

struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(CyberpunkTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(CyberpunkTheme.neonCyan.opacity(0.3), lineWidth: 1)
            )
    }
}

struct GlowingBorderModifier: ViewModifier {
    let color: Color
    let lineWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color, lineWidth: lineWidth)
                    .shadow(color: color.opacity(0.8), radius: 4)
                    .shadow(color: color.opacity(0.5), radius: 8)
            )
    }
}

// MARK: - View Extensions

extension View {
    func cyberpunkCard() -> some View {
        modifier(CyberpunkTheme.cardStyle())
    }

    func glowingBorder(color: Color = CyberpunkTheme.neonCyan, lineWidth: CGFloat = 2) -> some View {
        modifier(CyberpunkTheme.glowingBorder(color: color, lineWidth: lineWidth))
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Font Styles

extension Font {
    static let cyberpunkTitle = Font.system(size: 28, weight: .bold, design: .monospaced)
    static let cyberpunkHeadline = Font.system(size: 20, weight: .semibold, design: .monospaced)
    static let cyberpunkBody = Font.system(size: 16, weight: .regular, design: .monospaced)
    static let cyberpunkCaption = Font.system(size: 12, weight: .regular, design: .monospaced)
    static let cyberpunkGauge = Font.system(size: 48, weight: .bold, design: .monospaced)
    static let cyberpunkGaugeSmall = Font.system(size: 24, weight: .semibold, design: .monospaced)
}
