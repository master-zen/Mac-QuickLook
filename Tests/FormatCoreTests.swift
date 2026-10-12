import XCTest
import Foundation
#if SWIFT_PACKAGE
@testable import FormatCore
#endif

final class FormatCoreTests: XCTestCase {
    func testTwelveKinds() {
        XCTAssertEqual(FileSummary.Kind.allCases.count, 12)
        XCTAssertEqual(FileSummary.Kind.fromExtension("GPX"), .gpx)
        XCTAssertNil(FileSummary.Kind.fromExtension("exe"))
    }
    func testHTMLSafety() {
        XCTAssertEqual(FileSummary.escaped("<script>&\"'"), "&lt;script&gt;&amp;&quot;&#39;")
    }
    func testSubtitle() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".srt")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("1\n00:00:01,000 --> 00:00:02,000\nHello".utf8).write(to: url)
        let summary = try FileSummary.inspect(url)
        XCTAssertTrue(summary.properties.contains("Subtitle cues: 1"))
        XCTAssertTrue(String(decoding: summary.html(), as: UTF8.self).contains("Hello"))
    }
    func testRejectsEmpty() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".cube")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data().write(to: url)
        XCTAssertThrowsError(try FileSummary.inspect(url))
    }
    func testRejectsXMLDTD() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".gpx")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("<!DOCTYPE gpx><gpx/>".utf8).write(to: url)
        XCTAssertThrowsError(try FileSummary.inspect(url))
    }
}
