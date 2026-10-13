import Foundation
import FoundationXML

enum MetadataDecoder {
    static func decode(kind: FileSummary.Kind, text: String, data: Data) throws -> [String] {
        switch kind {
        case .cube: return try cube(text)
        case .gpx: return try gpx(text).details
        case .fcpxml: return try xml(text, mode: .fcpxml)
        case .srt, .vtt, .ass, .ssa: return try subtitle(text, kind: kind)
        case .edl: return try edl(text)
        case .otio: return try otio(data)
        case .gcode: return try gcode(text)
        case .torrent, .ase: throw FileSummary.ReadError.unsupportedType
        }
    }

    static func cube(_ text: String) throws -> [String] {
        var title: String?
        var dimensions: [String] = []
        var expectedEntries: Int?
        var entries = 0
        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") { continue }
            let parts = line.split(whereSeparator: \.isWhitespace)
            guard let first = parts.first else { continue }
            switch first.uppercased() {
            case "TITLE":
                title = String(line.dropFirst(first.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            case "LUT_3D_SIZE", "LUT_1D_SIZE":
                guard parts.count == 2, let count = Int(parts[1]), (2...256).contains(count) else { throw FileSummary.ReadError.invalidFormat }
                dimensions.append("\(first.uppercased()): \(count)")
                expectedEntries = first.uppercased() == "LUT_3D_SIZE" ? count * count * count : count
            case "DOMAIN_MIN", "DOMAIN_MAX":
                guard parts.count == 4, parts.dropFirst().allSatisfy({ Double($0)?.isFinite == true }) else { throw FileSummary.ReadError.invalidFormat }
            default:
                if parts.count == 3 && parts.allSatisfy({ Double($0)?.isFinite == true }) {
                    entries += 1
                } else {
                    throw FileSummary.ReadError.invalidFormat
                }
            }
        }
        guard !dimensions.isEmpty, entries > 0 else { throw FileSummary.ReadError.invalidFormat }
        var lines: [String] = dimensions
        if let title = title { lines.insert("Title: \(title)", at: 0) }
        lines.append("Entries: \(entries)")
        if let expectedEntries = expectedEntries { lines.append(entries == expectedEntries ? "Grid: complete" : "Grid: incomplete or nonstandard") }
        return lines
    }

    static func cubeSwatches(_ text: String) -> [FileSummary.Swatch] {
        var gridSize: Int?
        var is3D = false
        for line in text.components(separatedBy: .newlines) {
            let parts = line.split(whereSeparator: \.isWhitespace)
            guard parts.count == 2, let size = Int(parts[1]) else { continue }
            if parts[0].uppercased() == "LUT_3D_SIZE" {
                gridSize = size
                is3D = true
                break
            }
            if parts[0].uppercased() == "LUT_1D_SIZE" {
                gridSize = size
                break
            }
        }
        guard let size = gridSize, (2...256).contains(size) else { return [] }
        let targets = Set((0..<min(size, 20)).map { position -> Int in
            let index = Int((Double(position) * Double(size - 1) / Double(max(1, min(size, 20) - 1))).rounded())
            return is3D ? index * (size * size + size + 1) : index
        })
        var index = 0
        var colors: [(Int, String)] = []
        for rawLine in text.components(separatedBy: .newlines) {
            let parts = rawLine.split(whereSeparator: \.isWhitespace)
            let values = parts.compactMap { Double($0) }
            guard parts.count == 3, values.count == 3, values.allSatisfy({ $0.isFinite }) else { continue }
            if targets.contains(index) {
                let channels = values.map { Int((min(1, max(0, $0)) * 255).rounded()) }
                let hex = String(format: "#%02X%02X%02X", channels[0], channels[1], channels[2])
                colors.append((index, hex))
            }
            index += 1
            if colors.count == targets.count { break }
        }
        return colors.sorted { $0.0 < $1.0 }.enumerated().map { order, item in
            FileSummary.Swatch(name: "Sample \(order + 1)", model: "RGB", hex: item.1)
        }
    }

    struct GPXResult {
        let details: [String]
        let coordinates: [FileSummary.Coordinate]
    }

    static func gpx(_ text: String) throws -> GPXResult {
        let lower = text.lowercased()
        guard !lower.contains("<!doctype"), !lower.contains("<!entity") else { throw FileSummary.ReadError.invalidFormat }
        let parser = XMLParser(data: Data(text.utf8))
        parser.shouldResolveExternalEntities = false
        let delegate = XMLCountDelegate()
        delegate.collectTrack = true
        parser.delegate = delegate
        guard parser.parse(), delegate.root == "gpx" else { throw FileSummary.ReadError.invalidFormat }
        let details = ["Tracks: \(delegate.count("trk"))", "Track points: \(delegate.count("trkpt"))", "Routes: \(delegate.count("rte"))", "Route points: \(delegate.count("rtept"))", "Waypoints: \(delegate.count("wpt"))"]
        return GPXResult(details: details, coordinates: delegate.coordinates)
    }

    enum XMLMode { case gpx, fcpxml }

    static func xml(_ text: String, mode: XMLMode) throws -> [String] {
        let lower = text.lowercased()
        guard !lower.contains("<!doctype"), !lower.contains("<!entity") else { throw FileSummary.ReadError.invalidFormat }
        let parser = XMLParser(data: Data(text.utf8))
        parser.shouldResolveExternalEntities = false
        let delegate = XMLCountDelegate()
        parser.delegate = delegate
        guard parser.parse(), delegate.root == (mode == .gpx ? "gpx" : "fcpxml") else { throw FileSummary.ReadError.invalidFormat }
        if mode == .gpx {
            return ["Tracks: \(delegate.count("trk"))", "Track points: \(delegate.count("trkpt"))", "Routes: \(delegate.count("rte"))", "Route points: \(delegate.count("rtept"))", "Waypoints: \(delegate.count("wpt"))"]
        }
        return ["Projects: \(delegate.count("project"))", "Sequences: \(delegate.count("sequence"))", "Clips: \(delegate.count("clip") + delegate.count("asset-clip") + delegate.count("mc-clip") + delegate.count("sync-clip"))", "Assets: \(delegate.count("asset"))", "Effects: \(delegate.count("effect"))"]
    }

    static func subtitle(_ text: String, kind: FileSummary.Kind) throws -> [String] {
        let lines = text.components(separatedBy: .newlines)
        switch kind {
        case .vtt:
            guard text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("WEBVTT") else { throw FileSummary.ReadError.invalidFormat }
            let cues = lines.filter { $0.contains("-->") }.count
            return ["Cues: \(cues)", "Format: WebVTT"]
        case .srt:
            let cues = lines.filter { $0.contains("-->") }.count
            guard cues > 0 else { throw FileSummary.ReadError.invalidFormat }
            return ["Cues: \(cues)", "Format: SubRip"]
        case .ass, .ssa:
            guard text.lowercased().contains("[events]") else { throw FileSummary.ReadError.invalidFormat }
            let cues = lines.filter { $0.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("dialogue:") }.count
            let styles = lines.filter { $0.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("style:") }.count
            return ["Dialogue events: \(cues)", "Styles: \(styles)"]
        default: throw FileSummary.ReadError.unsupportedType
        }
    }

    static func gcode(_ text: String) throws -> [String] {
        var movement = 0
        var extrusion = 0
        var toolChanges = 0
        var layers = Set<Int>()
        for original in text.components(separatedBy: .newlines) {
            let line = original.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            if line.hasPrefix(";LAYER:"), let number = Int(line.dropFirst(7)) { layers.insert(number) }
            if line.hasPrefix("T"), Int(line.dropFirst()) != nil { toolChanges += 1 }
            let command = line.components(separatedBy: ";").first ?? ""
            let parts = command.split(whereSeparator: \.isWhitespace)
            if let token = parts.first, ["G0", "G00", "G1", "G01", "G2", "G02", "G3", "G03"].contains(String(token)) {
                movement += 1
                if parts.dropFirst().contains(where: { $0.hasPrefix("E") }) { extrusion += 1 }
            }
        }
        guard movement > 0 else { throw FileSummary.ReadError.invalidFormat }
        return ["Motion commands: \(movement)", "Extrusion commands: \(extrusion)", "Tool selects: \(toolChanges)", "Annotated layers: \(layers.count)"]
    }

    static func edl(_ text: String) throws -> [String] {
        let lines = text.components(separatedBy: .newlines)
        let count = lines.filter {
            let line = $0.trimmingCharacters(in: .whitespaces)
            return line.count >= 4 && line.prefix(3).allSatisfy(\.isNumber) && line.dropFirst(3).first?.isWhitespace == true
        }.count
        guard count > 0 else { throw FileSummary.ReadError.invalidFormat }
        var detail = ["Events: \(count)"]
        if let title = lines.first(where: { $0.uppercased().hasPrefix("TITLE:") }) { detail.append(title.trimmingCharacters(in: .whitespaces)) }
        if let fcm = lines.first(where: { $0.uppercased().hasPrefix("FCM:") }) { detail.append(fcm.trimmingCharacters(in: .whitespaces)) }
        return detail
    }

    static func otio(_ data: Data) throws -> [String] {
        let root = try JSONSerialization.jsonObject(with: data)
        guard let rootMap = root as? [String: Any], let schema = rootMap["OTIO_SCHEMA"] as? String else { throw FileSummary.ReadError.invalidFormat }
        var stack: [Any] = [root]
        var visited = 0
        var clips = 0
        var tracks = 0
        var transitions = 0
        while let item = stack.popLast() {
            visited += 1
            guard visited <= 50_000 else { throw FileSummary.ReadError.tooLarge }
            if let map = item as? [String: Any] {
                if let value = map["OTIO_SCHEMA"] as? String {
                    if value.hasPrefix("Clip.") { clips += 1 }
                    if value.hasPrefix("Track.") { tracks += 1 }
                    if value.hasPrefix("Transition.") { transitions += 1 }
                }
                stack.append(contentsOf: map.values)
            } else if let list = item as? [Any] {
                stack.append(contentsOf: list)
            }
        }
        return ["Schema: \(schema)", "Clips: \(clips)", "Tracks: \(tracks)", "Transitions: \(transitions)"]
    }
}

private final class XMLCountDelegate: NSObject, XMLParserDelegate {
    private var counts: [String: Int] = [:]
    var root: String?
    var collectTrack = false
    private(set) var coordinates: [FileSummary.Coordinate] = []
    private var observed = 0
    private var stride = 1
    private var pendingSegment = true

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        let name = String(elementName.split(separator: ":").last ?? "").lowercased()
        if root == nil { root = name }
        counts[name, default: 0] += 1
        guard collectTrack else { return }
        if name == "trkseg" || name == "rte" { pendingSegment = true }
        guard name == "trkpt" || name == "rtept" else { return }
        guard let latitudeText = attributeDict["lat"], let longitudeText = attributeDict["lon"],
              let latitude = Double(latitudeText), let longitude = Double(longitudeText),
              latitude.isFinite, longitude.isFinite, (-90...90).contains(latitude), (-180...180).contains(longitude) else { return }
        observed += 1
        if (observed - 1) % stride == 0 {
            coordinates.append(.init(latitude: latitude, longitude: longitude, breakBefore: pendingSegment))
            pendingSegment = false
            if coordinates.count >= 2048 {
                var retained: [FileSummary.Coordinate] = []
                for (index, coordinate) in coordinates.enumerated() where index.isMultiple(of: 2) {
                    let precedingBreak = index > 0 && coordinates[index - 1].breakBefore
                    retained.append(.init(latitude: coordinate.latitude, longitude: coordinate.longitude, breakBefore: coordinate.breakBefore || precedingBreak))
                }
                coordinates = retained
                stride *= 2
            }
        }
    }
    func count(_ element: String) -> Int { counts[element, default: 0] }
}
