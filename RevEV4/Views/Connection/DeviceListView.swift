//
//  DeviceListView.swift
//  RevEV4
//

import SwiftUI

/// View for selecting a Bluetooth device
struct DeviceListView: View {
    @Bindable var viewModel: OBDViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                CyberpunkTheme.darkBackground.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Status
                    ConnectionStatusView(state: viewModel.connectionState)
                        .padding(.horizontal)

                    // Device list
                    if viewModel.discoveredDevices.isEmpty && viewModel.connectionState == .scanning {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(CyberpunkTheme.neonCyan)
                        Text("Scanning for devices...")
                            .font(.cyberpunkBody)
                            .foregroundStyle(CyberpunkTheme.textSecondary)
                        Spacer()
                    } else if viewModel.discoveredDevices.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 48))
                                .foregroundStyle(CyberpunkTheme.neonCyan.opacity(0.5))

                            Text("No devices found")
                                .font(.cyberpunkBody)
                                .foregroundStyle(CyberpunkTheme.textSecondary)

                            Text("Make sure your OBD adapter is powered on")
                                .font(.cyberpunkCaption)
                                .foregroundStyle(CyberpunkTheme.textMuted)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.discoveredDevices) { device in
                                    DeviceRow(device: device) {
                                        viewModel.connect(to: device)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Scan button
                    Button {
                        if viewModel.connectionState == .scanning {
                            viewModel.stopScanning()
                        } else {
                            viewModel.startScanning()
                        }
                    } label: {
                        HStack {
                            Image(systemName: viewModel.connectionState == .scanning ? "stop.fill" : "antenna.radiowaves.left.and.right")
                            Text(viewModel.connectionState == .scanning ? "Stop Scanning" : "Scan for Devices")
                        }
                        .font(.cyberpunkBody)
                        .foregroundStyle(CyberpunkTheme.darkBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(CyberpunkTheme.neonCyan)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: CyberpunkTheme.neonCyan.opacity(0.5), radius: 8)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Connect Device")
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

struct DeviceRow: View {
    let device: BluetoothDevice
    let onConnect: () -> Void

    var body: some View {
        Button(action: onConnect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.cyberpunkBody)
                        .foregroundStyle(CyberpunkTheme.textPrimary)

                    Text(device.id.uuidString.prefix(8) + "...")
                        .font(.cyberpunkCaption)
                        .foregroundStyle(CyberpunkTheme.textMuted)
                }

                Spacer()

                // Signal strength indicator
                HStack(spacing: 2) {
                    ForEach(0..<4) { bar in
                        Rectangle()
                            .fill(signalColor(for: bar))
                            .frame(width: 4, height: CGFloat(6 + bar * 4))
                    }
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(CyberpunkTheme.neonCyan)
            }
            .padding()
            .cyberpunkCard()
            .glowingBorder(color: CyberpunkTheme.neonCyan.opacity(0.3), lineWidth: 1)
        }
    }

    private func signalColor(for bar: Int) -> Color {
        let strength = min(4, max(0, (device.rssi + 100) / 20))
        return bar < strength ? CyberpunkTheme.neonCyan : CyberpunkTheme.textMuted
    }
}

#Preview {
    DeviceListView(viewModel: OBDViewModel())
}
