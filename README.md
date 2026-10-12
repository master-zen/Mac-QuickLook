# Mac QuickLook Modern

Independent modern rebuild targeting macOS 13–27, with a single host application that embeds Quick Look Preview and Thumbnail extensions. The original `master` branch remains intact as the upstream archival catalog.

Formats in the first modern build: CUBE, GPX, SRT, VTT, ASS, SSA, EDL, OTIO, FCPXML, ASE, Torrent, G-code.

This branch is a **new implementation**; it does not repackage old `.qlgenerator` or `.pkg` files. A listed format is not a guarantee that Finder will select our extension; macOS and installed apps resolve preview providers by content type.

## Build

Install XcodeGen and Xcode on macOS, then run:

    brew install xcodegen
    swift test
    xcodegen generate --spec project.yml
    xcodebuild -project MacQuickLookModern.xcodeproj -scheme MacQuickLookModern -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build test

Unsigned builds are development-only. Public distribution requires signing, notarization and actual Finder acceptance testing. CI can compile and check embedded `.appex` files but does not prove every macOS version is compatible.
