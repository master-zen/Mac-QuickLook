# v0.6.0-alpha.1 — Finder Quick Look ONLY

**Developer pre-release. Not a signed or notarized installer.**

## Purpose
This project adds macOS Finder **Space-bar Quick Look previews and thumbnails** only. The host application is a minimal container for two Quick Look app extensions.

## Changed since v0.5.0-alpha.1
- Removed the host application's file picker and built-in file inspection interface.
- Removed all 12 document-opening associations (`CFBundleDocumentTypes`). Installing this app must **not change which app opens a file on double-click**.
- Removed the host's unused user-selected-file sandbox entitlement.
- Kept the imported UTI declarations for Finder classification and the two embedded Preview/Thumbnail extensions.
- Tightened automated metadata and bundle validation to catch accidental reintroduction of document opening.
- Added read-only Finder extension/UTI diagnostics (`Scripts/diagnose-finder.zsh`).

## Available Quick Look previews
`.cube`, `.ase`, `.gpx`, `.srt`, `.vtt`, `.ass`, `.ssa`, `.edl`, `.otio`, `.fcpxml`, `.torrent`, `.gcode`.

Supported means that a decoder and Quick Look extension declaration are present, **not** that Finder provider selection was verified on every macOS release. System or third-party UTIs may take precedence; diagnose with `mdls` and `pluginkit`.

## Validation and limitations
macOS CI can build the .app and inspect both embedded .appex bundles. An actual signed installation and Finder Space/thumbnail test are still required on supported systems, especially macOS 13. The 76 old generator bundles and 11 installers have not been ported, and video/3D/ebook/archive renderers are not yet part of this modern branch.

## Asset warning
`MacQuickLookModern-UNSIGNED-DEV.zip` is an **unsigned developer artifact**, not a standard installer. Gatekeeper may reject it. **Do not disable SIP or Gatekeeper.** A real distributable must be Developer ID signed, notarized and tested before it is called stable.
