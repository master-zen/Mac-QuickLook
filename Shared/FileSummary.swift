import Foundation

struct FileSummary {
    enum Failure: LocalizedError {
        case unsupported, empty, tooLarge, corrupt
        var errorDescription: String? {
            switch self {
            case .unsupported: return "Unsupported file extension"
            case .empty: return "File is empty"
            case .tooLarge: return "File exceeds 8 MiB"
            case .corrupt: return "Invalid or unsupported file contents"
            }
        }
    }
    enum Kind: String, CaseIterable {
        case cube, gpx, srt, vtt, ass, ssa, edl, otio, fcpxml, ase, torrent, gcode
        static func fromExtension(_ value: String) -> Kind? { Kind(rawValue: value.lowercased()) }
    }
    let kind: Kind
    let name: String
    let properties: [String]
    let text: String

    static func inspect(_ url: URL) throws -> FileSummary {
        guard let kind = Kind.fromExtension(url.pathExtension) else { throw Failure.unsupported }
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        let data = try file.read(upToCount: 8_388_609) ?? Data()
        guard !data.isEmpty else { throw Failure.empty }
        guard data.count <= 8_388_608 else { throw Failure.tooLarge }
        var properties = ["Size: \(data.count) bytes"]
        if kind == .ase {
            guard data.count >= 12, Array(data.prefix(4)) == [65, 83, 69, 70] else { throw Failure.corrupt }
            properties.append("Adobe Swatch Exchange binary")
            return FileSummary(kind: kind, name: url.lastPathComponent, properties: properties, text: "Color swatch metadata")
        }
        if kind == .torrent {
            guard data.first == 100, data.last == 101 else { throw Failure.corrupt }
            properties.append("BitTorrent metadata, no network access")
            return FileSummary(kind: kind, name: url.lastPathComponent, properties: properties, text: "Binary torrent file")
        }
        let contents: String
        if data.starts(with: [0xFF, 0xFE]), let value = String(data: data, encoding: .utf16LittleEndian) {
            contents = value
        } else if data.starts(with: [0xFE, 0xFF]), let value = String(data: data, encoding: .utf16BigEndian) {
            contents = value
        } else if let value = String(data: data, encoding: .utf8) {
            contents = value
        } else { throw Failure.corrupt }
        guard !contents.contains("\0") else { throw Failure.corrupt }
        let lines = contents.components(separatedBy: .newlines)
        switch kind {
        case .cube:
            let sizes = lines.filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("LUT_3D_SIZE ") }
            guard sizes.count == 1 else { throw Failure.corrupt }
            properties.append(sizes[0])
        case .gpx:
            guard contents.contains("<gpx"), !contents.contains("<!DOCTYPE"), !contents.contains("<!ENTITY") else { throw Failure.corrupt }
            properties.append("Track points: \(contents.components(separatedBy: "<trkpt").count - 1)")
        case .srt, .vtt:
            properties.append("Subtitle cues: \(lines.filter { $0.contains("-->") }.count)")
        case .ass, .ssa:
            properties.append("Dialogue events: \(lines.filter { $0.hasPrefix("Dialogue:") }.count)")
        case .edl:
            properties.append("Edit events: \(lines.filter { $0.first?.isNumber == true }.count)")
        case .otio:
            guard (try? JSONSerialization.jsonObject(with: data)) != nil else { throw Failure.corrupt }
            properties.append("OpenTimelineIO JSON document")
        case .fcpxml:
            guard contents.contains("<fcpxml"), !contents.contains("<!DOCTYPE"), !contents.contains("<!ENTITY") else { throw Failure.corrupt }
            properties.append("Final Cut Pro XML document")
        case .gcode:
            properties.append("Motion lines: \(lines.filter { $0.hasPrefix("G0 ") || $0.hasPrefix("G1 ") }.count)")
        default: break
        }
        return FileSummary(kind: kind, name: url.lastPathComponent, properties: properties, text: String(contents.prefix(32_000)))
    }

    static func escaped(_ input: String) -> String {
        input.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    func html() -> Data {
        let items = properties.map { "<li>\(Self.escaped($0))</li>" }.joined()
        let markup = """
        <!doctype html><html><head><meta charset="utf-8"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'"><style>body{font:14px -apple-system,system-ui;padding:25px;background:#fff;color:#222;line-height:1.5}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#eef0f4;padding:15px;border-radius:8px}@media(prefers-color-scheme:dark){body{background:#202126;color:#eee}pre{background:#2c2d33}}</style></head>
        <body><h2>\(Self.escaped(name))</h2><p>\(Self.escaped(kind.rawValue.uppercased()))</p><ul>\(items)</ul><pre>\(Self.escaped(text))</pre></body></html>
        """
        return Data(markup.utf8)
    }
}
