import Foundation

struct FileSummary {
    enum ReadError: LocalizedError {
        case unsupportedType
        case tooLarge
        case invalidText
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .unsupportedType: return "This file type is not supported."
            case .tooLarge: return "This file exceeds the safe preview size limit."
            case .invalidText: return "This text encoding is not supported."
            case .invalidFormat: return "The file has an invalid or unsupported structure."
            }
        }
    }

    enum Kind: String, CaseIterable {
        case cube = "Color LUT"
        case gpx = "GPS Track"
        case srt = "SubRip Subtitles"
        case vtt = "WebVTT Subtitles"
        case ass = "Advanced SubStation Alpha"
        case ssa = "SubStation Alpha"
        case edl = "Edit Decision List"
        case otio = "OpenTimelineIO"
        case fcpxml = "Final Cut Pro XML"
        case ase = "Adobe Swatch Exchange"
        case torrent = "BitTorrent Metadata"
        case gcode = "G-code"

        static func forExtension(_ ext: String) -> Kind? {
            switch ext.lowercased() {
            case "cube": return .cube
            case "gpx": return .gpx
            case "srt": return .srt
            case "vtt": return .vtt
            case "ass": return .ass
            case "ssa": return .ssa
            case "edl": return .edl
            case "otio": return .otio
            case "fcpxml": return .fcpxml
            case "ase": return .ase
            case "torrent": return .torrent
            case "gcode": return .gcode
            default: return nil
            }
        }

        var fileExtension: String {
            switch self {
            case .cube: return "cube"
            case .gpx: return "gpx"
            case .srt: return "srt"
            case .vtt: return "vtt"
            case .ass: return "ass"
            case .ssa: return "ssa"
            case .edl: return "edl"
            case .otio: return "otio"
            case .fcpxml: return "fcpxml"
            case .ase: return "ase"
            case .torrent: return "torrent"
            case .gcode: return "gcode"
            }
        }

        var isBinary: Bool { self == .ase || self == .torrent }
    }

    struct Swatch {
        let name: String
        let model: String
        let hex: String?
    }

    struct Coordinate {
        let latitude: Double
        let longitude: Double
        let breakBefore: Bool

        init(latitude: Double, longitude: Double, breakBefore: Bool = false) {
            self.latitude = latitude
            self.longitude = longitude
            self.breakBefore = breakBefore
        }
    }

    static let maximumBytes = 8_388_608
    static let maximumPreviewCharacters = 32_000

    let kind: Kind
    let fileName: String
    let details: [String]
    let text: String
    let swatches: [Swatch]
    let track: [Coordinate]

    static func read(_ url: URL) throws -> FileSummary {
        guard let kind = Kind.forExtension(url.pathExtension) else { throw ReadError.unsupportedType }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: maximumBytes + 1) ?? Data()
        guard data.count <= maximumBytes else { throw ReadError.tooLarge }
        guard !data.isEmpty else { throw ReadError.invalidFormat }
        if kind == .torrent {
            return FileSummary(kind: kind, fileName: url.lastPathComponent, details: try TorrentDecoder.metadata(data), text: "", swatches: [], track: [])
        }
        if kind == .ase {
            let swatches = try ASEDecoder.parse(data)
            let count = swatches.count
            let models = Set(swatches.map(\.model)).sorted().joined(separator: ", ")
            return FileSummary(kind: kind, fileName: url.lastPathComponent, details: ["Swatches: \(count)", "Models: \(models)"], text: "", swatches: Array(swatches.prefix(120)), track: [])
        }
        let input = try decodeText(data)
        let result: [String]
        var track: [Coordinate] = []
        var swatches: [Swatch] = []
        if kind == .gpx {
            let parsed = try MetadataDecoder.gpx(input)
            result = parsed.details
            track = parsed.coordinates
        } else {
            result = try MetadataDecoder.decode(kind: kind, text: input, data: data)
            if kind == .cube { swatches = MetadataDecoder.cubeSwatches(input) }
        }
        let excerpt = String(input.prefix(maximumPreviewCharacters))
        return FileSummary(kind: kind, fileName: url.lastPathComponent, details: ["Size: \(data.count) bytes"] + result, text: excerpt, swatches: swatches, track: track)
    }

    static func decodeText(_ data: Data) throws -> String {
        let text: String?
        if data.starts(with: [0xFF, 0xFE]) {
            text = String(data: data, encoding: .utf16LittleEndian)
        } else if data.starts(with: [0xFE, 0xFF]) {
            text = String(data: data, encoding: .utf16BigEndian)
        } else {
            text = String(data: data, encoding: .utf8)
        }
        guard let text = text, !text.contains("\0") else { throw ReadError.invalidText }
        return text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
    }
}
