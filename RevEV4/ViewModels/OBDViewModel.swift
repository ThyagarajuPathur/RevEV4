//
//  OBDViewModel.swift
//  RevEV4
//

import Foundation
import Combine

/// ViewModel for OBD-II connection and data
@Observable
@MainActor
final class OBDViewModel {
    // MARK: - Services

    let bluetoothService: BluetoothService
    let protocolService: OBDProtocolService

    // MARK: - State

    var connectionState: ConnectionState {
        bluetoothService.connectionState
    }

    var discoveredDevices: [BluetoothDevice] {
        bluetoothService.discoveredDevices
    }

    var connectedDevice: BluetoothDevice? {
        bluetoothService.connectedDevice
    }

    var obdData: OBDData {
        protocolService.obdData
    }

    var isPolling: Bool {
        protocolService.isPolling
    }

    var isInitialized: Bool {
        protocolService.isInitialized
    }

    // MARK: - Initialization

    init() {
        self.bluetoothService = BluetoothService()
        self.protocolService = OBDProtocolService(bluetoothService: bluetoothService)
    }

    // MARK: - Connection Methods

    func startScanning() {
        bluetoothService.startScanning()
    }

    func stopScanning() {
        bluetoothService.stopScanning()
    }

    func connect(to device: BluetoothDevice) {
        bluetoothService.connect(to: device)
    }

    func disconnect() {
        protocolService.stopPolling()
        bluetoothService.disconnect()
    }

    // MARK: - OBD Methods

    func initializeAdapter() async {
        do {
            try await protocolService.initializeAdapter()
        } catch {
            print("Failed to initialize adapter: \(error)")
        }
    }

    func startPolling() {
        protocolService.startPolling()
    }

    func stopPolling() {
        protocolService.stopPolling()
    }

    func sendRawCommand(_ command: String) async -> String {
        do {
            return try await protocolService.sendRawCommand(command)
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
}
