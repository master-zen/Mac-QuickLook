#!/bin/zsh
set -euo pipefail
: "${SIGNED_APP:?SIGNED_APP must be an already Developer ID signed .app}"
: "${NOTARY_PROFILE:?NOTARY_PROFILE must refer to your notarytool keychain profile}"
APP="${SIGNED_APP:A}"
ROOT="${0:A:h:h}"
OUT="$ROOT/Dist"
[[ -d "$APP" && "$APP" == *.app ]] || exit 1
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP"
mkdir -p "$OUT"
/usr/bin/ditto -c -k --keepParent "$APP" "$OUT/MacQuickLookModern-notary.zip"
/usr/bin/xcrun notarytool submit "$OUT/MacQuickLookModern-notary.zip" --keychain-profile "$NOTARY_PROFILE" --wait
/usr/bin/xcrun stapler staple "$APP"
/usr/bin/xcrun stapler validate "$APP"
/usr/bin/hdiutil create -ov -format UDZO -volname 'Mac QuickLook Modern' -srcfolder "$APP" "$OUT/MacQuickLookModern.dmg"
/usr/bin/xcrun notarytool submit "$OUT/MacQuickLookModern.dmg" --keychain-profile "$NOTARY_PROFILE" --wait
/usr/bin/xcrun stapler staple "$OUT/MacQuickLookModern.dmg"
/usr/bin/xcrun stapler validate "$OUT/MacQuickLookModern.dmg"
shasum -a 256 "$OUT/MacQuickLookModern.dmg"
