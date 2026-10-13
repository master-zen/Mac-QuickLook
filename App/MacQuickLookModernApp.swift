import AppKit
import SwiftUI

@main
struct MacQuickLookModernApp: App {
    @State private var selected: FileSummary?
    @State private var errorMessage: String?

    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mac QuickLook Modern").font(.title2.bold())
                        Text("Preview extensions · macOS 13+").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Inspect File") { inspectFile() }
                }
                Divider()
                Text("Supported Format Parsers").font(.headline)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 10)], spacing: 10) {
                    ForEach(FileSummary.Kind.allCases, id: \.rawValue) { kind in
                        HStack {
                            Text(kind.fileExtension.uppercased()).font(.system(.caption, design: .monospaced).bold())
                            Spacer()
                            Image(systemName: "doc.text.magnifyingglass").foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                Divider()
                if let selected = selected {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(selected.fileName).font(.headline)
                        Text(selected.kind.rawValue).font(.caption).foregroundColor(.secondary)
                        ForEach(selected.details, id: \.self) { value in Text(value).font(.caption) }
                        if !selected.swatches.isEmpty {
                            HStack(spacing: 2) {
                                ForEach(Array(selected.swatches.enumerated()), id: \.offset) { pair in
                                    Rectangle().fill(color(for: pair.element.hex)).frame(maxWidth: .infinity)
                                }
                            }
                            .frame(height: 42)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        if selected.track.count > 1 {
                            GeometryReader { geometry in
                                let points = TrackGeometry.normalized(selected.track)
                                Path { path in
                                    for (index, point) in points.enumerated() {
                                        let position = CGPoint(x: point.x * geometry.size.width, y: point.y * geometry.size.height)
                                        if index == 0 || point.breakBefore { path.move(to: position) }
                                        else { path.addLine(to: position) }
                                    }
                                }
                                .stroke(.mint, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            }
                            .frame(height: 150)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                } else if let errorMessage = errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                } else {
                    Text("Choose a file to inspect, or press Space on a supported file in Finder.")
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(minWidth: 570, minHeight: 410)
        }
    }

    private func color(for hex: String?) -> Color {
        guard let hex, hex.count == 7, let value = Int(hex.dropFirst(), radix: 16) else { return .gray }
        return Color(red: Double((value >> 16) & 0xFF) / 255,
                     green: Double((value >> 8) & 0xFF) / 255,
                     blue: Double(value & 0xFF) / 255)
    }

    private func inspectFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            do {
                selected = try FileSummary.read(url)
                errorMessage = nil
            } catch {
                selected = nil
                errorMessage = error.localizedDescription
            }
        }
    }
}
