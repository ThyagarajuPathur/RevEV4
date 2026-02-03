//
//  Data+Hex.swift
//  RevEV4
//

import Foundation

extension Data {
    /// Convert data to hex string
    var hexString: String {
        map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    /// Create data from hex string
    init?(hexString: String) {
        let hex = hexString.replacingOccurrences(of: " ", with: "")

        guard hex.count % 2 == 0 else { return nil }

        var data = Data()
        var index = hex.startIndex

        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else {
                return nil
            }
            data.append(byte)
            index = nextIndex
        }

        self = data
    }
}

extension String {
    /// Convert hex string to bytes array
    var hexBytes: [UInt8] {
        let hex = self.replacingOccurrences(of: " ", with: "")
        var bytes: [UInt8] = []
        var index = hex.startIndex

        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
            if let byte = UInt8(hex[index..<nextIndex], radix: 16) {
                bytes.append(byte)
            }
            index = nextIndex
        }

        return bytes
    }

    /// Format as hex pairs separated by spaces
    var formattedHex: String {
        let cleaned = self.replacingOccurrences(of: " ", with: "").uppercased()
        var result = ""
        var index = cleaned.startIndex

        while index < cleaned.endIndex {
            let nextIndex = cleaned.index(index, offsetBy: 2, limitedBy: cleaned.endIndex) ?? cleaned.endIndex
            if !result.isEmpty {
                result += " "
            }
            result += String(cleaned[index..<nextIndex])
            index = nextIndex
        }

        return result
    }
}
