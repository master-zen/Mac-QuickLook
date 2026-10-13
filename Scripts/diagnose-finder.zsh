#!/bin/zsh
# Read-only diagnostic. Does not reset caches, change handlers or modify Gatekeeper.
set -u
HOST_ID="cn.masterzen.MacQuickLookModern"
PREVIEW_ID="${HOST_ID}.Preview"
THUMBNAIL_ID="${HOST_ID}.Thumbnail"
APP="${MACQUICKLOOK_APP:-/Applications/MacQuickLookModern.app}"
echo "===== macOS ====="
/usr/bin/sw_vers
echo "===== Host app ====="
echo "Path: $APP"
if [[ ! -d "$APP" ]]; then
  echo "MISSING: No installed app at the path above."
  echo "Extracting a ZIP into Downloads is not a completed installation."
else
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist" 2>/dev/null || true
  for ext in QuickLookPreview QuickLookThumbnail; do
    file="$APP/Contents/PlugIns/$ext.appex"
    if [[ -d "$file" ]]; then
      echo "Found $ext.appex"
      /usr/bin/codesign --verify --strict --verbose=2 "$file" 2>&1 || echo "SIGNING INVALID OR ABSENT for $ext"
    else
      echo "MISSING: $ext.appex"
    fi
  done
  echo "Host signing:"
  /usr/bin/codesign --verify --deep --strict --verbose=2 "$APP" 2>&1 || echo "SIGNING INVALID OR ABSENT"
  echo "Gatekeeper assessment:"
  /usr/sbin/spctl --assess --type execute -v "$APP" 2>&1 || echo "NOT ACCEPTED as a distributed macOS application"
  echo "Quarantine (informational):"
  /usr/bin/xattr -p com.apple.quarantine "$APP" 2>/dev/null || echo "none reported"
fi
echo "===== Quick Look Preview extension registration ====="
/usr/bin/pluginkit -m -p com.apple.quicklook.preview 2>&1 | /usr/bin/grep -F "$PREVIEW_ID" || echo "NOT REGISTERED (or invisible to pluginkit)"
echo "===== Quick Look Thumbnail extension registration ====="
/usr/bin/pluginkit -m -p com.apple.quicklook.thumbnail 2>&1 | /usr/bin/grep -F "$THUMBNAIL_ID" || echo "NOT REGISTERED (or invisible to pluginkit)"
echo "===== Finder Quick Look plugins (read-only) ====="
/usr/bin/qlmanage -m plugins 2>&1 | /usr/bin/grep -E "masterzen|MacQuickLook" || echo "No matching plugin in qlmanage output"
echo "===== File type test ====="
if (( $# > 0 )); then
  for file in "$@"; do
    if [[ ! -f "$file" ]]; then
      echo "Missing sample: $file"
      continue
    fi
    echo "$file"
    /usr/bin/mdls -name kMDItemContentType -name kMDItemContentTypeTree "$file" 2>&1
  done
else
  echo "Pass one or more full file paths: zsh Scripts/diagnose-finder.zsh /path/to/example.gpx /path/to/example.srt"
fi
echo "===== Interpretation ====="
echo "Unsigned/notarization failure + missing plugin = installation trust/registration issue."
echo "Registered extensions + different file UTI = content type dispatch mismatch candidate."
echo "Both may coexist. This script cannot establish which provider Finder invoked."
echo "Never disable SIP or Gatekeeper to force the build to run."
