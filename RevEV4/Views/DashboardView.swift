//
//  DashboardView.swift
//  RevEV4
//
//  Main dashboard view with gauges, throttle indicator, and controls
//

import SwiftUI

/// Main dashboard view showing gauges and controls
struct DashboardView: View {
    @State var obdViewModel: OBDViewModel
    @State var audioViewModel: AudioViewModel

    @State private var showDeviceList = false
    @State private var showEngineSelector = false
    @State private var showDemoMode = false

    init() {
        let obd = OBDViewModel()
        _obdViewModel = State(initialValue: obd)
        _audioViewModel = State(initialValue: AudioViewModel())
    }

    var body: some View {
        ZStack {
            // Background
            CyberpunkTheme.darkBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding()

                Spacer()

                // Gauges
                gaugesView
                    .padding()

                // Throttle indicator
                ThrottleIndicator(
                    throttle: audioViewModel.throttleState,
                    gear: audioViewModel.currentGear
                )
                .padding(.horizontal)

                Spacer()

                // Controls
                controlsView
                    .padding()

                // Bottom bar
                bottomBar
            }
        }
        .onChange(of: obdViewModel.connectionState) { oldState, newState in
            handleConnectionStateChange(from: oldState, to: newState)
        }
        .onChange(of: obdViewModel.obdData.rpm) { _, newRPM in
            audioViewModel.updateFromOBD(
                rpm: newRPM,
                acceleratorPedal: obdViewModel.obdData.acceleratorPedal
            )
        }
        .onChange(of: obdViewModel.obdData.acceleratorPedal) { _, newAccel in
            audioViewModel.updateFromOBD(
                rpm: obdViewModel.obdData.rpm,
                acceleratorPedal: newAccel
            )
        }
        .sheet(isPresented: $showDeviceList) {
            DeviceListView(viewModel: obdViewModel)
        }
        .sheet(isPresented: $showEngineSelector) {
            EngineSelectorView(viewModel: audioViewModel)
        }
        .sheet(isPresented: $showDemoMode) {
            DemoView(audioViewModel: audioViewModel)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("REVEV4")
                    .font(.cyberpunkTitle)
                    .foregroundStyle(CyberpunkTheme.cyanMagentaGradient)

                Text("Physics-Based Engine Sound")
                    .font(.cyberpunkCaption)
                    .foregroundStyle(CyberpunkTheme.textMuted)
            }

            Spacer()

            CompactConnectionStatus(
                state: obdViewModel.connectionState,
                deviceName: obdViewModel.connectedDevice?.name
            ) {
                showDeviceList = true
            }
        }
    }

    // MARK: - Gauges

    private var gaugesView: some View {
        HStack(spacing: 16) {
            RPMGaugeView(
                rpm: obdViewModel.obdData.rpm,
                maxRPM: audioViewModel.currentProfile.maxRPM
            )

            AcceleratorPedalGauge(
                position: obdViewModel.obdData.acceleratorPedal
            )

            SpeedGaugeView(
                speed: obdViewModel.obdData.speed,
                maxSpeed: 260
            )
        }
    }

    // MARK: - Controls

    private var controlsView: some View {
        VStack(spacing: 16) {
            // Engine sound toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ENGINE SOUND")
                        .font(.cyberpunkCaption)
                        .foregroundStyle(CyberpunkTheme.textMuted)

                    Text(audioViewModel.currentProfile.name)
                        .font(.cyberpunkBody)
                        .foregroundStyle(CyberpunkTheme.textPrimary)
                }

                Spacer()

                // Settings button
                Button {
                    showEngineSelector = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20))
                        .foregroundStyle(CyberpunkTheme.neonCyan)
                        .padding(12)
                        .background(CyberpunkTheme.cardBackground)
                        .clipShape(Circle())
                }

                // Play/Stop button
                Button {
                    audioViewModel.togglePlayback()
                } label: {
                    Image(systemName: audioViewModel.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(audioViewModel.isPlaying ? CyberpunkTheme.neonRed : CyberpunkTheme.neonGreen)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(CyberpunkTheme.cardBackground)
                                .shadow(color: (audioViewModel.isPlaying ? CyberpunkTheme.neonRed : CyberpunkTheme.neonGreen).opacity(0.5), radius: 8)
                        )
                }
            }
            .padding()
            .cyberpunkCard()

            // Polling toggle (only when connected)
            if obdViewModel.connectionState == .ready {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DATA POLLING")
                            .font(.cyberpunkCaption)
                            .foregroundStyle(CyberpunkTheme.textMuted)

                        Text(obdViewModel.isPolling ? "Active" : "Stopped")
                            .font(.cyberpunkBody)
                            .foregroundStyle(obdViewModel.isPolling ? CyberpunkTheme.neonGreen : CyberpunkTheme.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { obdViewModel.isPolling },
                        set: { isOn in
                            if isOn {
                                obdViewModel.startPolling()
                            } else {
                                obdViewModel.stopPolling()
                            }
                        }
                    ))
                    .tint(CyberpunkTheme.neonGreen)
                }
                .padding()
                .cyberpunkCard()
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            // Demo mode button
            Button {
                showDemoMode = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                    Text("Demo")
                }
                .font(.cyberpunkCaption)
                .foregroundStyle(CyberpunkTheme.neonCyan)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(CyberpunkTheme.cardBackground)
                .clipShape(Capsule())
            }

            Spacer()

            // Pitch indicator
            if audioViewModel.isPlaying {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                    Text("Pitch: \(Int(audioViewModel.currentPitch))¢")
                }
                .font(.cyberpunkCaption)
                .foregroundStyle(CyberpunkTheme.neonMagenta)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(CyberpunkTheme.cardBackground)
                .clipShape(Capsule())
            }

            Spacer()

            // Disconnect button (when connected)
            if obdViewModel.connectionState.isConnected {
                Button {
                    obdViewModel.disconnect()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                        Text("Disconnect")
                    }
                    .font(.cyberpunkCaption)
                    .foregroundStyle(CyberpunkTheme.neonRed)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(CyberpunkTheme.cardBackground)
                    .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(CyberpunkTheme.surfaceBackground)
    }

    // MARK: - State Handling

    private func handleConnectionStateChange(from oldState: ConnectionState, to newState: ConnectionState) {
        switch newState {
        case .initializing:
            // Auto-initialize the adapter
            Task {
                await obdViewModel.initializeAdapter()
            }
        case .ready:
            // Auto-start polling when ready
            obdViewModel.startPolling()
            // Auto-start audio playback
            if !audioViewModel.isPlaying {
                audioViewModel.start()
            }
        case .disconnected:
            // Stop polling on disconnect
            obdViewModel.stopPolling()
        default:
            break
        }
    }
}

#Preview {
    DashboardView()
}
