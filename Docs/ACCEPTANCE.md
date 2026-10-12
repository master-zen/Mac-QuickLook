# Finder acceptance matrix

The deployment target is macOS 13.0; this is not proof of runtime compatibility.

| macOS | Processor | CI runner | Native build and tests | Finder preview | Finder thumbnail |
| --- | --- | --- | --- | --- | --- |
| 13 | Intel / Apple silicon (supported models) | External Mac required | Not verified | Not verified | Not verified |
| 14 | Apple silicon | macos-14 | CI configured | Not verified | Not verified |
| 15 | Intel | macos-15-intel | CI configured | Not verified | Not verified |
| 26 | Apple silicon | macos-26 | CI configured | Not verified | Not verified |
| 27 | Apple silicon | xcode-27 (preview) | CI configured | Not verified | Not verified |

Native CI is automated for build, unit tests and extension bundle inspection. CI does not currently automate actual Finder selection or Quick Look rendering.

Install a correctly signed App in /Applications. Launch it once. Test sample files in Finder with the Space key, the preview column, and icon thumbnails. Confirm the selected content type and registered extension:

```sh
mdls -name kMDItemContentType /path/to/example.cube
pluginkit -m -p com.apple.quicklook.preview
pluginkit -m -p com.apple.quicklook.thumbnail
```

Validate 12 formats, large-file rejection, malicious HTML text, reinstall, extension priority when conflicting applications exist, and offline operation. Never disable SIP or Gatekeeper just to make this application load.

Older Intel systems are not equivalent to macOS 27 on Apple silicon; distribute only after validation on target systems.
