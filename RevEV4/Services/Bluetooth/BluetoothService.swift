//
//  BluetoothService.swift
//  RevEV4
//

import Foundation
import CoreBluetooth

/// Core Bluetooth management service for ELM327 adapters
@Observable
final class BluetoothService: NSObject, @unchecked Sendable {
    // MARK: - Published State

    var connectionState: ConnectionState = .disconnected
    private(set) var discoveredDevices: [BluetoothDevice] = []
    private(set) var connectedDevice: BluetoothDevice?

    // MARK: - Private Properties

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?
    private var preferredWriteType: CBCharacteristicWriteType = .withResponse

    private var dataBuffer = Data()

    /// Continuation for async response waiting
    private var responseContinuation: CheckedContinuation<String, Error>?

    /// Auto-connect settings
    var autoConnectEnabled: Bool = true
    private let lastDeviceKey = "RevEV4.LastConnectedDeviceUUID"

    // MARK: - Initialization

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Auto-Connect

    /// Get the last connected device UUID
    private var lastConnectedDeviceUUID: UUID? {
        get {
            guard let uuidString = UserDefaults.standard.string(forKey: lastDeviceKey) else { return nil }
            return UUID(uuidString: uuidString)
        }
        set {
            UserDefaults.standard.set(newValue?.uuidString, forKey: lastDeviceKey)
        }
    }

    /// Save the current device for auto-reconnect
    private func saveLastDevice(_ device: BluetoothDevice) {
        lastConnectedDeviceUUID = device.peripheral.identifier
        print("DEBUG: Saved device for auto-connect: \(device.name)")
    }

    /// Check if device matches last connected or is a known OBD adapter
    private func shouldAutoConnect(to device: BluetoothDevice) -> Bool {
        // Priority 1: Last connected device
        if let lastUUID = lastConnectedDeviceUUID, device.peripheral.identifier == lastUUID {
            print("DEBUG: Found last connected device: \(device.name)")
            return true
        }

        // Priority 2: Known OBD adapter names
        let name = device.name.lowercased()
        let isKnownOBD = name.contains("obd") ||
                         name.contains("elm") ||
                         name.contains("vlink") ||
                         name.contains("veepeak") ||
                         name.contains("ios-vlink")

        if isKnownOBD {
            print("DEBUG: Found known OBD adapter: \(device.name)")
            return true
        }

        return false
    }

    // MARK: - Public Methods

    /// Start scanning for ELM327 devices
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            connectionState = .error("Bluetooth is not available")
            return
        }

        discoveredDevices.removeAll()
        connectionState = .scanning

        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        // Stop scanning after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if self?.connectionState == .scanning {
                self?.stopScanning()
            }
        }
    }

    /// Stop scanning for devices
    func stopScanning() {
        centralManager.stopScan()
        if connectionState == .scanning {
            connectionState = .disconnected
        }
    }

    /// Connect to a specific device
    func connect(to device: BluetoothDevice) {
        stopScanning()
        connectionState = .connecting
        centralManager.connect(device.peripheral, options: nil)
    }

    /// Disconnect from current device
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        cleanup()
    }

    /// Send a command and wait for response
    @MainActor
    func sendCommand(_ command: String, timeout: TimeInterval = 3.0) async throws -> String {
        guard let writeChar = writeCharacteristic,
              let peripheral = connectedPeripheral else {
            throw BluetoothError.notConnected
        }

        // Cancel any pending continuation to prevent "multiple resumes" crash
        if let pending = responseContinuation {
            pending.resume(throwing: BluetoothError.timeout)
            responseContinuation = nil
        }

        // Clear buffer before sending
        dataBuffer.removeAll()

        // Add carriage return to command
        let commandData = "\(command)\r".data(using: .ascii)!

        return try await withCheckedThrowingContinuation { continuation in
            self.responseContinuation = continuation

            peripheral.writeValue(commandData, for: writeChar, type: self.preferredWriteType)

            // Timeout handling
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                guard let self = self else { return }
                if self.responseContinuation != nil {
                    let bufferContent = String(data: self.dataBuffer, encoding: .ascii) ?? "NON-ASCII"
                    print("DEBUG: Command '\(command)' timed out after \(timeout)s. Buffer: [\(bufferContent)]")
                    self.responseContinuation?.resume(throwing: BluetoothError.timeout)
                    self.responseContinuation = nil
                }
            }
        }
    }

    // MARK: - Private Methods

    private func cleanup() {
        connectedPeripheral = nil
        connectedDevice = nil
        writeCharacteristic = nil
        notifyCharacteristic = nil
        dataBuffer.removeAll()
        responseContinuation = nil
        connectionState = .disconnected
    }

    private func processReceivedData(_ data: Data) {
        dataBuffer.append(data)

        // Check for response terminator '>'
        guard let responseString = String(data: dataBuffer, encoding: .ascii) else {
            return
        }

        if responseString.contains(">") {
            // Some devices send multiple lines before the '>'
            // We want the whole response up to the '>'
            let response = responseString
                .replacingOccurrences(of: ">", with: "")

            dataBuffer.removeAll()

            if let continuation = responseContinuation {
                continuation.resume(returning: response)
                responseContinuation = nil
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                // Auto-start scanning when Bluetooth is ready
                if self.autoConnectEnabled && self.connectionState == .disconnected {
                    print("DEBUG: Bluetooth ready, starting auto-scan...")
                    self.startScanning()
                }
            case .poweredOff:
                self.connectionState = .error("Bluetooth is turned off")
                self.cleanup()
            case .unauthorized:
                self.connectionState = .error("Bluetooth permission denied")
            case .unsupported:
                self.connectionState = .error("Bluetooth not supported")
            default:
                break
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Filter for likely OBD adapters by name
        let name = peripheral.name ?? ""
        let isLikelyOBD = name.lowercased().contains("obd") ||
                          name.lowercased().contains("elm") ||
                          name.lowercased().contains("vlink") ||
                          name.lowercased().contains("veepeak") ||
                          name.lowercased().contains("car") ||
                          name.contains("IOS-Vlink") ||
                          name.contains("OBDII")

        // Only add devices with names or likely OBD devices
        guard !name.isEmpty || isLikelyOBD else { return }

        let device = BluetoothDevice(peripheral: peripheral, rssi: RSSI.intValue)

        Task { @MainActor in
            if !self.discoveredDevices.contains(where: { $0.id == device.id }) {
                self.discoveredDevices.append(device)

                // Auto-connect if enabled and device matches criteria
                if self.autoConnectEnabled &&
                   self.connectionState == .scanning &&
                   self.shouldAutoConnect(to: device) {
                    print("DEBUG: Auto-connecting to \(device.name)...")
                    self.connect(to: device)
                }
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            self.connectedPeripheral = peripheral
            self.connectedDevice = self.discoveredDevices.first { $0.id == peripheral.identifier }
            peripheral.delegate = self
            self.connectionState = .connected

            // Save for auto-reconnect
            if let device = self.connectedDevice {
                self.saveLastDevice(device)
            }

            // Small delay to let BLE connection stabilize before service discovery
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

            // Discover services
            peripheral.discoverServices(nil)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.connectionState = .error(error?.localizedDescription ?? "Connection failed")
            self.cleanup()
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.cleanup()

            // Auto-reconnect after unexpected disconnect
            if self.autoConnectEnabled && error != nil {
                print("DEBUG: Connection lost (\(error?.localizedDescription ?? "unknown")), attempting auto-reconnect in 2s...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.startScanning()
                }
            }
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothService: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            guard error == nil, let services = peripheral.services else {
                self.connectionState = .error("Failed to discover services")
                return
            }

            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task { @MainActor in
            guard error == nil, let characteristics = service.characteristics else {
                return
            }

            let knownWriteUUID = ELM327UUIDs.writeCharacteristic(for: service.uuid)
            let knownNotifyUUID = ELM327UUIDs.notifyCharacteristic(for: service.uuid)

            for characteristic in characteristics {
                // Check against known UUIDs first
                if let writeUUID = knownWriteUUID, characteristic.uuid == writeUUID {
                    self.writeCharacteristic = characteristic
                    self.preferredWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                    print("DEBUG: Found known write characteristic: \(characteristic.uuid)")
                } else if let notifyUUID = knownNotifyUUID, characteristic.uuid == notifyUUID {
                    self.notifyCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("DEBUG: Found known notify characteristic: \(characteristic.uuid)")
                }

                // Fallback to property-based discovery if not already found
                if self.writeCharacteristic == nil {
                    if characteristic.properties.contains(.write) {
                        self.writeCharacteristic = characteristic
                        self.preferredWriteType = .withResponse
                    } else if characteristic.properties.contains(.writeWithoutResponse) {
                        self.writeCharacteristic = characteristic
                        self.preferredWriteType = .withoutResponse
                    }
                }

                if self.notifyCharacteristic == nil && characteristic.properties.contains(.notify) {
                    self.notifyCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }

            // Check if we have both characteristics
            if self.writeCharacteristic != nil && self.notifyCharacteristic != nil {
                print("DEBUG: Both characteristics found. Initializing...")
                self.connectionState = .initializing
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else {
            return
        }

        Task { @MainActor in
            self.processReceivedData(data)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            Task { @MainActor in
                self.responseContinuation?.resume(throwing: BluetoothError.writeFailed(error.localizedDescription))
                self.responseContinuation = nil
            }
        }
    }
}

// MARK: - Errors

enum BluetoothError: LocalizedError, Sendable {
    case notConnected
    case timeout
    case writeFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to device"
        case .timeout:
            return "Command timeout"
        case .writeFailed(let reason):
            return "Write failed: \(reason)"
        case .invalidResponse:
            return "Invalid response received"
        }
    }
}
