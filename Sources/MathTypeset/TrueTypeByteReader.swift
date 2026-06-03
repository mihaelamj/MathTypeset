import Foundation

/// Bounds-checked big-endian reader over a font table's bytes. Public so
/// consumers parsing their own font tables (sfnt directory, `head`/`hhea`/
/// `maxp`/`cmap`/`hmtx`, CFF `INDEX`/charstrings) can reuse the same checked
/// accessors the MATH reader uses. Out-of-range reads throw.
public struct TrueTypeByteReader {
    public var table: String
    public var bytes: [UInt8]

    public init(table: String, bytes: [UInt8]) {
        self.table = table
        self.bytes = bytes
    }

    public var count: Int {
        bytes.count
    }

    public func requireRange(offset: Int, count: Int) throws {
        guard offset >= 0, count >= 0, offset <= bytes.count, count <= bytes.count - offset else {
            throw TrueTypeFontError.truncated(
                table: table,
                offset: offset,
                needed: count,
                tableLength: bytes.count,
            )
        }
    }

    public func uint8(at offset: Int) throws -> UInt8 {
        try requireRange(offset: offset, count: 1)
        return bytes[offset]
    }

    public func tag(at offset: Int) throws -> String {
        try requireRange(offset: offset, count: 4)
        let tagBytes = Array(bytes[offset ..< offset + 4])
        if let tag = String(bytes: tagBytes, encoding: .ascii) {
            return tag
        }
        return tagBytes.map { String(format: "%02X", locale: Locale(identifier: "en_US_POSIX"), $0) }.joined()
    }

    public func uint16(at offset: Int) throws -> UInt16 {
        try requireRange(offset: offset, count: 2)
        return UInt16(bytes[offset]) << 8 | UInt16(bytes[offset + 1])
    }

    public func int16(at offset: Int) throws -> Int16 {
        try Int16(bitPattern: uint16(at: offset))
    }

    public func uint32(at offset: Int) throws -> UInt32 {
        try requireRange(offset: offset, count: 4)
        return UInt32(bytes[offset]) << 24
            | UInt32(bytes[offset + 1]) << 16
            | UInt32(bytes[offset + 2]) << 8
            | UInt32(bytes[offset + 3])
    }

    public func fixed16Dot16(at offset: Int) throws -> Double {
        let rawValue = try Int32(bitPattern: uint32(at: offset))
        return Double(rawValue) / 65536
    }
}
