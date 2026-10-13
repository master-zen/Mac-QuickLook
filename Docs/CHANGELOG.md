# Changelog

## 0.6.1 — Quick Look registration correction

- Reintroduces metadata-only document type registration with CFBundleTypeRole=None and LSHandlerRank=None so Launch Services can record custom UTIs without granting the host file-open or edit roles.
- Audits and built-bundle verifier assert all 12 registrations have non-opening roles.
- Adds macOS UTI probing and read-only signing/registration diagnostics after reports that an unsigned alpha failed in Finder.
- Still no signed/notarized distributable: this corrects registration metadata but requires a signed real Finder test.


## 0.6.0 — 2026-10-13 (Quick Look-only architecture)

- Removes the host application's file-picker and in-app inspector, including sandbox permission to read user-selected files.
- Removes all 12 document-open associations (CFBundleDocumentTypes); the app is not a file opener and does not claim default handlers.
- Keeps imported UTIs and both system Preview/Thumbnail extensions so macOS still has file-type registrations for Quick Look.
- CI auditing now rejects reintroduced open-file UI, document associations and file-picker entitlements.
- Updates install, compatibility and Finder acceptance instructions. This is still a development preview until real Finder testing and notarization.

## 0.5.0 — 2026-10-13

- Validates SRT and VTT cue timing rather than counting arbitrary arrows.
- Uses locale-independent integer coordinates in SVG route paths.

- Restores the complete decoders, fixtures, offline visualizations and legacy inventory in the remote modern branch.
- Validates complete CUBE grids, duplicate sizes, mixed 1D/3D sampling, and bounded color sampling memory.
- Rejects duplicate bencode dictionary keys and adds nine regression tests.
- Retains modern Quick Look protocol conformance and macOS 14-compatible Xcode project format.

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
