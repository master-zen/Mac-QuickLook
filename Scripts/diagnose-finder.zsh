#!/bin/zsh
# Read-only macOS Quick Look diagnostics. Never changes file associations.
set -euo pipefail
echo "Quick Look extension registration"
echo "================================="
echo
echo "Preview extension:"
/usr/bin/pluginkit -m -p com.apple.quicklook.preview 2>&1 | /usr/bin/grep -F "cn.masterzen.MacQuickLookModern.Preview" || echo "Not listed; install/launch a properly signed host app and verify registration."
echo
echo "Thumbnail extension:"
/usr/bin/pluginkit -m -p com.apple.quicklook.thumbnail 2>&1 | /usr/bin/grep -F "cn.masterzen.MacQuickLookModern.Thumbnail" || echo "Not listed; install/launch a properly signed host app and verify registration."
echo
if (( $# > 0 )); then
    file="$1"
    if [[ ! -f "$file" ]]; then
        print -u2 "File not found: $file"
        exit 2
    fi
    echo "Finder-assigned content type: $file"
    /usr/bin/mdls -name kMDItemContentType "$file"
    echo "Compare this UTI with QLSupportedContentTypes in the extension Info.plist."
else
    echo "Optional: pass a file path to inspect its Finder-assigned UTI."
fi
echo
echo "Then inspect a file in Finder with Space and check its icon thumbnail."
echo "This utility does not launch a file opener, reset caches, or change handlers."
