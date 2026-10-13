import SwiftUI

// A container for Finder's Quick Look extensions, not a document-opening app.
// All file reads and rendering happen inside the Preview/Thumbnail .appex targets.
@main
struct MacQuickLookModernApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mac QuickLook Modern").font(.title2.bold())
                    Text("Finder preview and thumbnails only")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                Label("Use Quick Look in Finder", systemImage: "eye")
                    .font(.headline)
                Text("Select a supported file in Finder, then press Space to preview it. Finder also requests thumbnails automatically.")
                    .fixedSize(horizontal: false, vertical: true)

                Text("This app is only a container for two macOS Quick Look extensions. It does not open, play, convert, or edit files.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                Text("Preview types").font(.headline)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                    ForEach(FileSummary.Kind.allCases, id: \.fileExtension) { kind in
                        Text("." + kind.fileExtension)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                Spacer(minLength: 0)
                Text("If macOS chooses another preview extension, review its file type registration and competing Quick Look providers.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .frame(minWidth: 490, minHeight: 390)
        }
    }
}
