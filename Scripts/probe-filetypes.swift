// Read-only check of the platform's preferred UTI for each supported extension.
// Run on actual macOS builds; this does not install, register or modify file handlers.
import Foundation
import UniformTypeIdentifiers

let appURL = URL(fileURLWithPath: "App/Info.plist")
guard
    let bytes = try? Data(contentsOf: appURL),
    let plist = try? PropertyListSerialization.propertyList(from: bytes, format: nil),
    let app = plist as? [String: Any],
    let types = app["UTImportedTypeDeclarations"] as? [[String: Any]]
else {
    fputs("Could not read App/Info.plist\n", stderr)
    exit(1)
}

print("Extension -> preferred macOS UTI -> declared Quick Look UTI")
var mismatches: [String] = []
for type in types {
    guard
        let declared = type["UTTypeIdentifier"] as? String,
        let tags = type["UTTypeTagSpecification"] as? [String: Any],
        let extensions = tags["public.filename-extension"] as? [String]
    else {
        fputs("Invalid UTI type declaration\n", stderr)
        exit(1)
    }
    for ext in extensions {
        let preferred = UTType(filenameExtension: ext)
        let resolved = preferred?.identifier ?? "(not resolved)"
        let dynamic = preferred?.isDynamic == true
        let result = resolved == declared ? "MATCH" : (dynamic ? "DYNAMIC" : "DIFFERENT")
        print(".\(ext) -> \(resolved) -> \(declared) [\(result)]")
        if result != "MATCH" {
            mismatches.append(".\(ext): macOS=\(resolved), extension=\(declared) [\(result)]")
        }
    }
}
if !mismatches.isEmpty {
    print("")
    print("UTI MISMATCH CANDIDATES: Finder may select a different preview provider.")
    print("These are diagnostics, not failures: custom UTIs may resolve only after app installation.")
    for message in mismatches { print(message) }
}

if let summaryPath = ProcessInfo.processInfo.environment["GITHUB_STEP_SUMMARY"] {
    let heading = "### UTI resolution for Quick Look\n\n"
    let rows = types.flatMap { type -> [String] in
        guard let declared = type["UTTypeIdentifier"] as? String,
              let tags = type["UTTypeTagSpecification"] as? [String: Any],
              let exts = tags["public.filename-extension"] as? [String] else { return [] }
        return exts.map { ext in
            let system = UTType(filenameExtension: ext)?.identifier ?? "(unknown)"
            return "| `.\(ext)` | `\(system)` | `\(declared)` | \(system == declared ? "Yes" : "No / check Finder") |"
        }
    }
    let markdown = heading + "| Extension | System preferred UTI | Extension UTI | Identical |\n|---|---|---|---|\n" + rows.joined(separator: "\n") + "\n\n"
    if let handle = FileHandle(forWritingAtPath: summaryPath) {
        handle.seekToEndOfFile()
        handle.write(Data(markdown.utf8))
        try? handle.close()
    }
}
