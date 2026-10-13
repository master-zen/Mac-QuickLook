import Foundation
import XCTest
#if canImport(FormatCore)
@testable import FormatCore
#endif

final class FormatCoreTests: XCTestCase {
    private func makeFile(_ name: String, content: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent(name)
        try Data(content.utf8).write(to: file)
        return file
    }

    private func clear(_ url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    func testHTMLSanitization() throws {
        let url = try makeFile("evil.srt", content: "1\n00:00:00,000 --> 00:00:01,000\n<script>alert('evil')</script>\n")
        defer { clear(url) }
        let html = String(data: PreviewHTML.render(try FileSummary.read(url)), encoding: .utf8)!
        XCTAssertFalse(html.contains("<script>alert"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
        XCTAssertTrue(html.contains("default-src 'none'"))
    }

    func testCubeSummary() throws {
        let url = try makeFile("grade.cube", content: "TITLE \"Film LUT\"\nLUT_3D_SIZE 2\n0 0 0\n0 0 1\n0 1 0\n0 1 1\n1 0 0\n1 0 1\n1 1 0\n1 1 1\n")
        defer { clear(url) }
        let summary = try FileSummary.read(url)
        XCTAssertTrue(summary.details.contains("LUT_3D_SIZE: 2"))
        XCTAssertTrue(summary.details.contains("Grid: complete"))
    }

    func testCubeRejectsInvalidNumbers() throws {
        let url = try makeFile("broken.cube", content: "LUT_3D_SIZE 2\nNaN 0 0\n")
        defer { clear(url) }
        XCTAssertThrowsError(try FileSummary.read(url))
    }

    func testGPXCountAndDTDRejection() throws {
        let valid = try makeFile("valid.gpx", content: "<?xml version=\"1.0\"?><gpx><trk><trkseg><trkpt lat=\"1\" lon=\"2\"/></trkseg></trk><wpt lat=\"1\" lon=\"2\"/></gpx>")
        let invalid = try makeFile("invalid.gpx", content: "<!DOCTYPE gpx [<!ENTITY x SYSTEM \"file:///etc/passwd\">]><gpx>&x;</gpx>")
        defer { clear(valid); clear(invalid) }
        XCTAssertTrue(try FileSummary.read(valid).details.contains("Track points: 1"))
        XCTAssertThrowsError(try FileSummary.read(invalid))
    }

    func testFCPXMLMetadata() throws {
        let url = try makeFile("project.fcpxml", content: "<fcpxml version=\"1.10\"><resources><asset id=\"a\"/></resources><library><event><project><sequence><spine><asset-clip/></spine></sequence></project></event></library></fcpxml>")
        defer { clear(url) }
        let summary = try FileSummary.read(url)
        XCTAssertTrue(summary.details.contains("Clips: 1"))
        XCTAssertTrue(summary.details.contains("Assets: 1"))
    }

    func testSRTVTTASS() throws {
        let srt = try makeFile("test.srt", content: "1\n00:00:01,000 --> 00:00:02,000\nHello")
        let vtt = try makeFile("test.vtt", content: "WEBVTT\n\n00:01.000 --> 00:02.000\nHello")
        let ass = try makeFile("test.ass", content: "[Script Info]\nTitle: Test\n[Events]\nDialogue: 0,0:00:01,0:00:03,Default,,0,0,0,,Hello")
        defer { clear(srt); clear(vtt); clear(ass) }
        for url in [srt, vtt, ass] {
            XCTAssertEqual(try FileSummary.read(url).kind.fileExtension, url.pathExtension)
        }
    }

    func testEDL() throws {
        let url = try makeFile("cut.edl", content: "TITLE: Cut A\nFCM: NON-DROP FRAME\n001  AX       V     C        00:00:00:00 00:00:01:00 01:00:00:00 01:00:01:00\n")
        defer { clear(url) }
        XCTAssertTrue(try FileSummary.read(url).details.contains("Events: 1"))
    }

    func testOTIO() throws {
        let url = try makeFile("timeline.otio", content: "{\"OTIO_SCHEMA\":\"Timeline.1\",\"tracks\":{\"OTIO_SCHEMA\":\"Track.1\",\"children\":[{\"OTIO_SCHEMA\":\"Clip.2\"}]}}")
        defer { clear(url) }
        let summary = try FileSummary.read(url)
        XCTAssertTrue(summary.details.contains("Clips: 1"))
        XCTAssertTrue(summary.details.contains("Tracks: 1"))
    }

    func testASESwatch() throws {
        var data = Data("ASEF".utf8)
        func u16(_ number: UInt16) -> Data { Data([UInt8(number >> 8), UInt8(number & 0xFF)]) }
        func u32(_ number: UInt32) -> Data { Data([UInt8(number >> 24), UInt8((number >> 16) & 0xFF), UInt8((number >> 8) & 0xFF), UInt8(number & 0xFF)]) }
        data.append(u16(1)); data.append(u16(0)); data.append(u32(1))
        var payload = Data()
        payload.append(u16(4))
        for scalar in [UInt16(82), 101, 100, 0] { payload.append(u16(scalar)) }
        payload.append(Data("RGB ".utf8))
        for value in [Float(1), 0, 0] { payload.append(u32(value.bitPattern)) }
        payload.append(u16(2))
        data.append(u16(1)); data.append(u32(UInt32(payload.count))); data.append(payload)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ase")
        defer { try? FileManager.default.removeItem(at: url) }
        try data.write(to: url)
        let summary = try FileSummary.read(url)
        XCTAssertEqual(summary.swatches.first?.hex, "#FF0000")
        XCTAssertEqual(summary.swatches.first?.name, "Red")
    }

    func testUnsupportedFileAndLargeFile() throws {
        let unknown = try makeFile("test.xyz", content: "data")
        let giant = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".srt")
        defer { clear(unknown); try? FileManager.default.removeItem(at: giant) }
        XCTAssertThrowsError(try FileSummary.read(unknown))
        try Data(repeating: 65, count: FileSummary.maximumBytes + 1).write(to: giant)
        XCTAssertThrowsError(try FileSummary.read(giant))
    }

    func testInvalidBinary() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ase")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data([0, 1, 2]).write(to: url)
        XCTAssertThrowsError(try FileSummary.read(url))
    }
}

extension FormatCoreTests {
    func testGCode() throws {
        let url = makeGCodeFixture()
        defer { try? FileManager.default.removeItem(at: url) }
        let summary = try FileSummary.read(url)
        XCTAssertTrue(summary.details.contains("Motion commands: 3"))
        XCTAssertTrue(summary.details.contains("Annotated layers: 2"))
    }

    func makeGCodeFixture() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".gcode")
        let content = ";LAYER:0\nG0 X0 Y0\nG1 X1 Y1 E0.3\n;LAYER:1\nG1 X2 Y2 E0.4\n"
        try! Data(content.utf8).write(to: url)
        return url
    }

    func testTorrentMeta() throws {
        let raw = "d8:announce15:https://tracker4:infod6:lengthi123e4:name8:film.mov12:piece lengthi16384e6:pieces20:01234567890123456789ee"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".torrent")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data(raw.utf8).write(to: url)
        let summary = try FileSummary.read(url)
        XCTAssertTrue(summary.details.contains("Files: 1"))
        XCTAssertTrue(summary.details.contains("Total bytes: 123"))
    }
}

extension FormatCoreTests {
    func testUTF16Subtitles() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".srt")
        defer { try? FileManager.default.removeItem(at: url) }
        let text = "1\n00:00:01,000 --> 00:00:02,000\n中文字幕\n"
        var data = Data([0xFF, 0xFE])
        data.append(text.data(using: .utf16LittleEndian)!)
        try data.write(to: url)
        let summary = try FileSummary.read(url)
        XCTAssertTrue(summary.text.contains("中文字幕"))
    }

    func testMalformedTorrentMetadata() throws {
        let inputs = ["d4:infod6:lengthi999999999999999999999ee", "d4:infod6:lengthi1ee", "d4:info5:wrong", "d4:infod6:lengthi-1e4:name1:aee"]
        for input in inputs {
            XCTAssertThrowsError(try TorrentDecoder.metadata(Data(input.utf8)))
        }
    }

    func testTruncatedASEInputs() throws {
        var data = Data("ASEF".utf8)
        data.append(Data([0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0x7F, 0xFF, 0xFF, 0xFF]))
        XCTAssertThrowsError(try ASEDecoder.parse(data))
        for length in 0..<data.count {
            XCTAssertThrowsError(try ASEDecoder.parse(Data(data.prefix(length))))
        }
    }
}

extension FormatCoreTests {
    func testBundledFixtures() throws {
        let fixtureFolder = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures")
        for kind in FileSummary.Kind.allCases {
            let file = fixtureFolder.appendingPathComponent("example.\(kind.fileExtension)")
            XCTAssertTrue(FileManager.default.fileExists(atPath: file.path), "Missing fixture: \(kind.fileExtension)")
            let parsed = try FileSummary.read(file)
            XCTAssertEqual(parsed.kind, kind)
        }
    }
}

extension FormatCoreTests {
    func testLUTDiagonalVisualization() throws {
        let url = try makeFile("diag.cube", content: "LUT_3D_SIZE 2\n0 0 0\n0 0 1\n0 1 0\n0 1 1\n1 0 0\n1 0 1\n1 1 0\n1 1 1\n")
        defer { clear(url) }
        let summary = try FileSummary.read(url)
        XCTAssertEqual(summary.swatches.compactMap(\.hex), ["#000000", "#FFFFFF"])
        let html = String(decoding: PreviewHTML.render(summary), as: UTF8.self)
        XCTAssertTrue(html.contains("background:#FFFFFF"))
        XCTAssertTrue(html.contains("LUT_3D_SIZE 2"))
    }

    func testGPXOfflineDrawingAndSegmentBreaks() throws {
        let url = try makeFile("track.gpx", content: "<gpx><trk><trkseg><trkpt lat=\"30\" lon=\"100\"/><trkpt lat=\"31\" lon=\"101\"/></trkseg><trkseg><trkpt lat=\"32\" lon=\"102\"/><trkpt lat=\"33\" lon=\"103\"/></trkseg></trk></gpx>")
        defer { clear(url) }
        let summary = try FileSummary.read(url)
        XCTAssertEqual(summary.track.count, 4)
        XCTAssertTrue(summary.track[2].breakBefore)
        let html = String(decoding: PreviewHTML.render(summary), as: UTF8.self)
        XCTAssertTrue(html.contains("Offline route outline"))
        XCTAssertTrue(html.contains("<svg"))
        XCTAssertFalse(html.contains("http://tile"))
        XCTAssertEqual(html.components(separatedBy: " M").count, 2)
        let points = TrackGeometry.normalized(summary.track)
        XCTAssertEqual(points.count, 4)
        XCTAssertTrue(points.allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
    }

    func testGPXDiscardsInvalidCoordinates() throws {
        let url = try makeFile("invalid-points.gpx", content: "<gpx><trk><trkseg><trkpt lat=\"9999\" lon=\"2\"/><trkpt lat=\"10\" lon=\"20\"/><trkpt lat=\"11\" lon=\"21\"/></trkseg></trk></gpx>")
        defer { clear(url) }
        let summary = try FileSummary.read(url)
        XCTAssertEqual(summary.track.count, 2)
        XCTAssertEqual(summary.details.first { $0.contains("Track points") }, "Track points: 3")
    }

    func testGPXAntimeridianGeometry() {
        let positions: [FileSummary.Coordinate] = [
            .init(latitude: 5, longitude: 179.9),
            .init(latitude: 5.1, longitude: -179.9)
        ]
        let plotted = TrackGeometry.normalized(positions)
        XCTAssertEqual(plotted.count, 2)
        XCTAssertTrue(plotted.allSatisfy { $0.x.isFinite && $0.y.isFinite })
        XCTAssertTrue(plotted.allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
    }

    func testNoRemoteOrExecutableHTML() throws {
        let url = try makeFile("<img src=x onerror=alert(1)>.srt", content: "1\n00:00:01,000 --> 00:00:02,000\n<iframe src=https://example.com></iframe>")
        defer { clear(url) }
        let html = String(decoding: PreviewHTML.render(try FileSummary.read(url)), as: UTF8.self)
        XCTAssertTrue(html.contains("&lt;iframe"))
        XCTAssertTrue(html.contains("&lt;img src=x"))
        XCTAssertFalse(html.contains("<iframe"))
        XCTAssertFalse(html.contains("<img"))
        XCTAssertTrue(html.contains("default-src 'none'"))
    }
}

extension FormatCoreTests {
    func testCubeRejectsIncompleteGrid() throws {
        let url = try makeFile("incomplete.cube", content: "LUT_3D_SIZE 2\n0 0 0\n1 1 1\n")
        defer { clear(url) }
        XCTAssertThrowsError(try FileSummary.read(url))
    }

    func testCubeRejectsDuplicateDimension() throws {
        let input = "LUT_3D_SIZE 2\nLUT_3D_SIZE 2\n" + Array(repeating: "0 0 0", count: 8).joined(separator: "\n")
        let url = try makeFile("duplicate.cube", content: input)
        defer { clear(url) }
        XCTAssertThrowsError(try FileSummary.read(url))
    }

    func testCubeRejectsDataBeforeDimensions() throws {
        let input = "0 0 0\nLUT_1D_SIZE 2\n1 1 1\n"
        let url = try makeFile("order.cube", content: input)
        defer { clear(url) }
        XCTAssertThrowsError(try FileSummary.read(url))
    }

    func testCombinedCubeCorrect3DSampling() throws {
        let input = "LUT_1D_SIZE 2\nLUT_3D_SIZE 2\n0.3 0.3 0.3\n0.8 0.8 0.8\n0 0 0\n0 0 1\n0 1 0\n0 1 1\n1 0 0\n1 0 1\n1 1 0\n1 1 1\n"
        let url = try makeFile("combined.cube", content: input)
        defer { clear(url) }
        let summary = try FileSummary.read(url)
        XCTAssertTrue(summary.details.contains("Entries: 10"))
        XCTAssertEqual(summary.swatches.compactMap(\.hex), ["#000000", "#FFFFFF"])
    }

    func testCubeOneDimensionalLUT() throws {
        let input = "TITLE Test\nLUT_1D_SIZE 2\n0 0 0\n1 1 1\n"
        let url = try makeFile("one.cube", content: input)
        defer { clear(url) }
        let summary = try FileSummary.read(url)
        XCTAssertTrue(summary.details.contains("LUT_1D_SIZE: 2"))
        XCTAssertEqual(summary.swatches.compactMap(\.hex), ["#000000", "#FFFFFF"])
    }

    func testCubeDoesNotRetainEntireHugeGrid() throws {
        let lines = ["LUT_1D_SIZE 20000"] + Array(repeating: "0.25 0.50 0.75", count: 20000)
        let url = try makeFile("large.cube", content: lines.joined(separator: "\n"))
        defer { clear(url) }
        let summary = try FileSummary.read(url)
        XCTAssertEqual(summary.swatches.count, 20)
        XCTAssertTrue(summary.details.contains("Entries: 20000"))
    }

    func testTorrentRejectsDuplicateBencodedKeys() throws {
        let input = "d4:infod6:lengthi1e6:lengthi2e4:name1:aee"
        XCTAssertThrowsError(try TorrentDecoder.metadata(Data(input.utf8)))
    }

    func testGPXRejectsMixedCaseDTD() throws {
        let xml = "<!DoCtYpE gpx><gpx><trk><trkseg/></trk></gpx>"
        let url = try makeFile("mixed.gpx", content: xml)
        defer { clear(url) }
        XCTAssertThrowsError(try FileSummary.read(url))
    }

    func testXMLTextInjectionEscapedInPreview() throws {
        let source = "<fcpxml><project name=\"&quot; onload=alert(1)\"/></fcpxml>"
        let url = try makeFile("injection.fcpxml", content: source)
        defer { clear(url) }
        let html = String(decoding: PreviewHTML.render(try FileSummary.read(url)), as: UTF8.self)
        XCTAssertTrue(html.contains("&lt;fcpxml&gt;"))
        XCTAssertFalse(html.contains("<project"))
    }
}
