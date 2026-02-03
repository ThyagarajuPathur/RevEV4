//
//  ConnectionStatusView.swift
//  RevEV4
//

import SwiftUI

/// View showing current connection status
struct ConnectionStatusView: View {
    let state: ConnectionState

    private var statusColor: Color {
        switch state {
        case .disconnected:
            return CyberpunkTheme.textMuted
        case .scanning, .connecting, .initializing:
            return CyberpunkTheme.neonYellow
        case .connected, .ready:
            return CyberpunkTheme.neonGreen
        case .error:
            return CyberpunkTheme.neonRed
        }
    }

    private var statusIcon: String {
        switch state {
        case .disconnected:
            return "link.badge.plus"
        case .scanning:
            return "antenna.radiowaves.left.and.right"
        case .connecting, .initializing:
            return "arrow.triangle.2.circlepath"
        case .connected, .ready:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: statusIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(statusColor)
                    .symbolEffect(.pulse, isActive: state == .scanning || state == .connecting || state == .initializing)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Connection Status")
                    .font(.cyberpunkCaption)
                    .foregroundStyle(CyberpunkTheme.textMuted)

                Text(state.displayText)
                    .font(.cyberpunkBody)
                    .foregroundStyle(statusColor)
            }

            Spacer()
        }
        .padding()
        .cyberpunkCard()
    }
}

/// Compact connection status for dashboard
struct CompactConnectionStatus: View {
    let state: ConnectionState
    let deviceName: String?
    let onTap: () -> Void

    private var statusColor: Color {
        switch state {
        case .ready:
            return CyberpunkTheme.neonGreen
        case .connected, .initializing:
            return CyberpunkTheme.neonYellow
        default:
            return CyberpunkTheme.neonRed
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: statusColor.opacity(0.8), radius: 4)

                if let name = deviceName, state.isConnected {
                    Text(name)
                        .font(.cyberpunkCaption)
                        .foregroundStyle(CyberpunkTheme.textPrimary)
                } else {
                    Text(state.displayText)
                        .font(.cyberpunkCaption)
                        .foregroundStyle(CyberpunkTheme.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(CyberpunkTheme.textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(CyberpunkTheme.cardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ZStack {
        CyberpunkTheme.darkBackground.ignoresSafeArea()

        VStack(spacing: 16) {
            ConnectionStatusView(state: .disconnected)
            ConnectionStatusView(state: .scanning)
            ConnectionStatusView(state: .connecting)
            ConnectionStatusView(state: .ready)
            ConnectionStatusView(state: .error("Connection lost"))

            HStack {
                CompactConnectionStatus(state: .ready, deviceName: "OBDII") {}
                CompactConnectionStatus(state: .disconnected, deviceName: nil) {}
            }
        }
        .padding()
    }
}
