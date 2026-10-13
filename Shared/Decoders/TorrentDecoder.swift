import Foundation

enum TorrentDecoder {
    indirect enum Value {
        case number(Int64)
        case bytes(Data)
        case list([Value])
        case dictionary([String: Value])

        var dictionary: [String: Value]? {
            if case let .dictionary(data) = self { return data }
            return nil
        }
        var list: [Value]? {
            if case let .list(data) = self { return data }
            return nil
        }
        var number: Int64? {
            if case let .number(data) = self { return data }
            return nil
        }
        var string: String? {
            if case let .bytes(data) = self { return String(data: data, encoding: .utf8) }
            return nil
        }
    }

    struct Parser {
        let bytes: [UInt8]
        var offset: Int = 0
        var count: Int = 0

        mutating func parse(depth: Int = 0) throws -> Value {
            count += 1
            guard depth <= 48, count <= 100_000, offset < bytes.count else { throw FileSummary.ReadError.invalidFormat }
            let char = bytes[offset]
            if char == 105 {
                offset += 1
                let start = offset
                while offset < bytes.count && bytes[offset] != 101 { offset += 1 }
                guard offset < bytes.count, let number = Int64(String(decoding: bytes[start..<offset], as: UTF8.self)) else { throw FileSummary.ReadError.invalidFormat }
                offset += 1
                return .number(number)
            }
            if char == 108 || char == 100 {
                offset += 1
                if char == 108 {
                    var items: [Value] = []
                    while offset < bytes.count && bytes[offset] != 101 {
                        items.append(try parse(depth: depth + 1))
                    }
                    guard offset < bytes.count else { throw FileSummary.ReadError.invalidFormat }
                    offset += 1
                    return .list(items)
                }
                var result: [String: Value] = [:]
                while offset < bytes.count && bytes[offset] != 101 {
                    let key = try parseBytes()
                    guard let keyText = String(data: key, encoding: .utf8) else { throw FileSummary.ReadError.invalidFormat }
                    result[keyText] = try parse(depth: depth + 1)
                }
                guard offset < bytes.count else { throw FileSummary.ReadError.invalidFormat }
                offset += 1
                return .dictionary(result)
            }
            return .bytes(try parseBytes())
        }

        mutating func parseBytes() throws -> Data {
            let start = offset
            while offset < bytes.count && bytes[offset] >= 48 && bytes[offset] <= 57 { offset += 1 }
            guard offset < bytes.count, offset > start, bytes[offset] == 58,
                  let length = Int(String(decoding: bytes[start..<offset], as: UTF8.self)),
                  length <= bytes.count - offset - 1 else { throw FileSummary.ReadError.invalidFormat }
            offset += 1
            let result = Data(bytes[offset..<(offset + length)])
            offset += length
            return result
        }
    }

    static func metadata(_ data: Data) throws -> [String] {
        var parser = Parser(bytes: Array(data))
        guard let top = try parser.parse().dictionary, parser.offset == data.count,
              let info = top["info"]?.dictionary else { throw FileSummary.ReadError.invalidFormat }
        let name = info["name.utf-8"]?.string ?? info["name"]?.string ?? "Untitled"
        var count = 0
        var total: Int64 = 0
        if let files = info["files"]?.list {
            guard files.count <= 20_000 else { throw FileSummary.ReadError.tooLarge }
            for file in files {
                guard let item = file.dictionary, let size = item["length"]?.number, size >= 0 else { throw FileSummary.ReadError.invalidFormat }
                let value = total.addingReportingOverflow(size)
                guard !value.overflow else { throw FileSummary.ReadError.invalidFormat }
                total = value.partialValue
                count += 1
            }
        } else if let size = info["length"]?.number, size >= 0 {
            count = 1
            total = size
        } else {
            throw FileSummary.ReadError.invalidFormat
        }
        var result = ["Name: \(name)", "Files: \(count)", "Total bytes: \(total)"]
        if let announce = top["announce"]?.string { result.append("Tracker: \(String(announce.prefix(180)))") }
        return result
    }
}
