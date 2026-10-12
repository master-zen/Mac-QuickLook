import AppKit
import SwiftUI

@main
struct MacQuickLookModernApp: App {
    @State private var selected: FileSummary?
    @State private var message = "Select a supported file in Finder and press Space, or inspect it here."

    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Mac QuickLook Modern").font(.title2.bold())
                    Spacer()
                    Button("Inspect File") { chooseFile() }
                }
                Text("One app · 12 formats · macOS 13+").foregroundColor(.secondary)
                Divider()
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                    ForEach(FileSummary.Kind.allCases, id: \.rawValue) { kind in
                        Text(kind.rawValue.uppercased())
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
                    }
                }
                Divider()
                if let selected {
                    Text(selected.name).font(.headline)
                    ForEach(selected.properties, id: \.self) { property in Text(property) }
                    ScrollView {
                        Text(selected.text).font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Text(message).foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(minWidth: 550, minHeight: 420)
        }
    }

    private func chooseFile() {
        let picker = NSOpenPanel()
        picker.canChooseDirectories = false
        picker.canChooseFiles = true
        guard picker.runModal() == .OK, let url = picker.url else { return }
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        do {
            selected = try FileSummary.inspect(url)
        } catch {
            selected = nil
            message = error.localizedDescription
        }
    }
}
