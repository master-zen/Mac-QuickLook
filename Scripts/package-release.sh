#!/bin/zsh
set -euo pipefail
: "${SIGNED_APP:?Set SIGNED_APP to the path of the signed and notarization-ready .app}"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE to the keychain profile configured for Apple notarytool}"
APP="${SIGNED_APP:A}"
ROOT="${0:A:h:h}"
DIST="$ROOT/Dist"
[[ -d "$APP" ]] || exit 1
[[ "$APP" == *.app ]] || exit 1
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP"
mkdir -p "$DIST"
/usr/bin/ditto -c -k --keepParent "$APP" "$DIST/MacQuickLookModern-notary.zip"
/usr/bin/xcrun notarytool submit "$DIST/MacQuickLookModern-notary.zip" --keychain-profile "$NOTARY_PROFILE" --wait
/usr/bin/xcrun stapler staple "$APP"
/usr/bin/xcrun stapler validate "$APP"
rm -f "$DIST/MacQuickLookModern.dmg"
/usr/bin/hdiutil create -ov -format UDZO -volname 'Mac QuickLook Modern' -srcfolder "$APP" "$DIST/MacQuickLookModern.dmg"
/usr/bin/xcrun notarytool submit "$DIST/MacQuickLookModern.dmg" --keychain-profile "$NOTARY_PROFILE" --wait
/usr/bin/xcrun stapler staple "$DIST/MacQuickLookModern.dmg"
/usr/bin/xcrun stapler validate "$DIST/MacQuickLookModern.dmg"
/usr/sbin/spctl --assess --type execute --verbose=2 "$APP"
shasum -a 256 "$DIST/MacQuickLookModern.dmg"
