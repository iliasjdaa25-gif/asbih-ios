import Foundation

/// Arbitrary-precision unsigned decimal counter capable of counting without upper integer limits.
struct BigCounter: Equatable {
    private(set) var rawDigits: String

    init(_ raw: String = "0") {
        self.rawDigits = BigCounter.normalize(raw)
    }

    var isZero: Bool {
        rawDigits == "0"
    }

    var isHundredMilestone: Bool {
        !isZero && rawDigits.hasSuffix("00")
    }

    /// Progress within a 33-bead tasbih cycle in the range `[0, 1]`.
    /// Exact non-zero multiples of 33 return `1.0` so the ring completes visually.
    var cycleProgress33: Double {
        if isZero { return 0.0 }
        let rem = remainder(modulo: 33)
        return rem == 0 ? 1.0 : Double(rem) / 33.0
    }

    /// Human-readable number grouped with commas every three digits.
    var formatted: String {
        let count = rawDigits.count
        guard count > 3 else { return rawDigits }

        var result = ""
        result.reserveCapacity(count + (count - 1) / 3)
        var groupIndex = 0

        for char in rawDigits.reversed() {
            if groupIndex > 0 && groupIndex % 3 == 0 {
                result.append(",")
            }
            result.append(char)
            groupIndex += 1
        }

        return String(result.reversed())
    }

    mutating func increment() {
        var bytes = [UInt8](rawDigits.utf8)
        var index = bytes.count - 1

        while index >= 0 {
            if bytes[index] < 57 { // '9'
                bytes[index] += 1
                rawDigits = String(decoding: bytes, as: UTF8.self)
                return
            }
            bytes[index] = 48 // '0'
            index -= 1
        }

        bytes.insert(49, at: 0) // '1'
        rawDigits = String(decoding: bytes, as: UTF8.self)
    }

    mutating func decrement() {
        if rawDigits == "0" { return }
        if rawDigits == "1" {
            rawDigits = "0"
            return
        }

        var bytes = [UInt8](rawDigits.utf8)
        var index = bytes.count - 1

        while index >= 0 {
            if bytes[index] > 48 { // '0'
                bytes[index] -= 1
                break
            }
            bytes[index] = 57 // '9'
            index -= 1
        }

        if bytes.count > 1 && bytes[0] == 48 {
            bytes.removeFirst()
        }

        rawDigits = String(decoding: bytes, as: UTF8.self)
    }

    mutating func reset() {
        rawDigits = "0"
    }

    func remainder(modulo modulus: Int) -> Int {
        guard modulus > 0 else { return 0 }
        var rem = 0
        for byte in rawDigits.utf8 {
            rem = (rem * 10 + Int(byte - 48)) % modulus
        }
        return rem
    }

    private static func normalize(_ raw: String) -> String {
        guard !raw.isEmpty else { return "0" }
        for byte in raw.utf8 where byte < 48 || byte > 57 {
            return "0"
        }
        let trimmed = raw.drop { $0 == "0" }
        return trimmed.isEmpty ? "0" : String(trimmed)
    }
}
