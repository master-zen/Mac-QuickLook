# v0.5.0-alpha.1 — Development Preview

This is a **pre-release**, not a production-ready macOS app.

## What is available

- A single SwiftUI host app with embedded Quick Look Preview and Thumbnail extensions.
- Twelve format handlers: .cube, .gpx, .srt, .vtt, .ass, .ssa, .edl, .otio, .fcpxml, .ase, .torrent, and .gcode.
- Local-only previews, constrained parsing, HTML escaping, LUT swatches and GPX track outlines.
- Automated tests and Xcode builds for selected macOS CI environments.

## What is not available

- The original repository's 76 legacy .qlgenerator bundles and 11 PKG installers have **not** been migrated. They were retired from the modern runtime, not recreated.
- Video playback and decoding, rich 3D model previews, ebooks, archive inspection, advanced image and code previews have not been reimplemented.
- Finder runtime provider selection and thumbnail rendering have **not** been confirmed on physical machines across macOS 13–27.
- Apple Developer ID signing and notarization have **not** been completed.

## Development asset warning

**MacQuickLookModern-UNSIGNED-DEV.zip contains an unsigned CI build for developer inspection only.** It is **not** an end-user installer and may be rejected by Gatekeeper. Do not disable Gatekeeper or SIP to use it. To use this app normally, first produce a properly signed and notarized release.

GitHub automatically attaches source ZIP and TAR archives for this tag. The code belongs to the `modern` branch, not the archival `master` branch.

For compatibility and outstanding work, see `Docs/ACCEPTANCE.md`, `Docs/MIGRATION.md`, and `Docs/RELEASE.md`.
