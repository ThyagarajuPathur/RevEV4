//
//  BluetoothDevice.swift
//  RevEV4
//

import Foundation
import CoreBluetooth

/// Represents a discovered Bluetooth device
struct BluetoothDevice: Identifiable, Hashable, @unchecked Sendable {
    let id: UUID
    let peripheral: CBPeripheral
    let name: String
    let rssi: Int

    init(peripheral: CBPeripheral, rssi: Int) {
        self.id = peripheral.identifier
        self.peripheral = peripheral
        self.name = peripheral.name ?? "Unknown Device"
        self.rssi = rssi
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: BluetoothDevice, rhs: BluetoothDevice) -> Bool {
        lhs.id == rhs.id
    }
}
