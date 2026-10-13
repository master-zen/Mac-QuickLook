# Changelog

## 0.3.0 — 2026-10-13

- LUT (`.cube`) adds diagonal color samples and color strip previews.
- GPX adds an entirely offline route outline, route segment breaks, bounded point sampling, and antimeridian handling.
- App file inspector and Finder thumbnail rendering show visual summaries for compatible LUT and GPX files.
- Adds sandbox entitlement for user-selected file reads and declares macOS `NSApplication` principal class.
- Registers a 32-point minimum thumbnail dimension.
- Adds native bundle integrity validation for Preview/Thumbnail `.appex` and declared UTTypes.
- Adds CI validation and keeps macOS 15 Intel, macOS 26 arm64, macOS 27 arm64 build/test lanes.
- Expands Swift tests from 17 to 22 and adds `Scripts/check.sh`.

This is a source milestone, not a notarized macOS release. Passing Linux/SwiftPM tests does not prove macOS 13–27 Finder compatibility.
