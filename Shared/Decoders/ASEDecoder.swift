import Foundation

enum ASEDecoder {
    static func parse(_ data: Data) throws -> [FileSummary.Swatch] {
        var cursor = Cursor(data)
        guard try cursor.bytes(4) == Array("ASEF".utf8) else { throw FileSummary.ReadError.invalidFormat }
        let major = try cursor.u16()
        _ = try cursor.u16()
        guard major == 1 else { throw FileSummary.ReadError.invalidFormat }
        let blocks = try cursor.u32()
        guard blocks <= 30_000 else { throw FileSummary.ReadError.tooLarge }
        var swatches: [FileSummary.Swatch] = []
        for _ in 0..<blocks {
            let kind = try cursor.u16()
            let length = try cursor.u32()
            guard length <= cursor.remaining else { throw FileSummary.ReadError.invalidFormat }
            let blockData = try cursor.dataBlock(Int(length))
            guard kind == 0x0001 else { continue }
            var entry = Cursor(blockData)
            let nameLength = Int(try entry.u16())
            guard nameLength <= 1024 else { throw FileSummary.ReadError.invalidFormat }
            var units: [UInt16] = []
            for _ in 0..<nameLength { units.append(try entry.u16()) }
            if units.last == 0 { units.removeLast() }
            let name = String(decoding: units, as: UTF16.self)
            let model = String(decoding: try entry.bytes(4), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            var hex: String?
            switch model {
            case "RGB":
                let r = try entry.float()
                let g = try entry.float()
                let b = try entry.float()
                guard r.isFinite, g.isFinite, b.isFinite else { throw FileSummary.ReadError.invalidFormat }
                hex = String(format: "#%02X%02X%02X", channel(r), channel(g), channel(b))
            case "CMYK":
                for _ in 0..<4 { guard try entry.float().isFinite else { throw FileSummary.ReadError.invalidFormat } }
            case "LAB":
                for _ in 0..<3 { guard try entry.float().isFinite else { throw FileSummary.ReadError.invalidFormat } }
            case "Gray":
                guard try entry.float().isFinite else { throw FileSummary.ReadError.invalidFormat }
            default:
                continue
            }
            _ = try entry.u16()
            swatches.append(FileSummary.Swatch(name: name.isEmpty ? "Untitled" : name, model: model, hex: hex))
            guard swatches.count <= 20_000 else { throw FileSummary.ReadError.tooLarge }
        }
        return swatches
    }

    static func channel(_ number: Float) -> Int {
        Int((min(1, max(0, number)) * 255).rounded())
    }

    struct Cursor {
        private let source: Data
        private var offset = 0
        var remaining: UInt32 { UInt32(max(0, source.count - offset)) }

        init(_ source: Data) { self.source = source }

        mutating func bytes(_ length: Int) throws -> [UInt8] {
            guard length >= 0, length <= source.count - offset else { throw FileSummary.ReadError.invalidFormat }
            let sequence = Array(source[offset..<(offset + length)])
            offset += length
            return sequence
        }

        mutating func dataBlock(_ length: Int) throws -> Data {
            Data(try bytes(length))
        }

        mutating func u16() throws -> UInt16 {
            let b = try bytes(2)
            return UInt16(b[0]) << 8 | UInt16(b[1])
        }

        mutating func u32() throws -> UInt32 {
            let b = try bytes(4)
            return UInt32(b[0]) << 24 | UInt32(b[1]) << 16 | UInt32(b[2]) << 8 | UInt32(b[3])
        }

        mutating func float() throws -> Float {
            Float(bitPattern: try u32())
        }
    }
}
