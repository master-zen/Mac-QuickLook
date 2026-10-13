from pathlib import Path
import plistlib
import sys

app = Path(sys.argv[1]).resolve()
assert app.is_dir() and app.suffix == '.app'
info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
assert info['CFBundleIdentifier'] == 'cn.masterzen.MacQuickLookModern'
assert info['NSPrincipalClass'] == 'NSApplication'
assert info['LSMinimumSystemVersion'].startswith('13.')
assert (app / 'Contents/MacOS/MacQuickLookModern').is_file()
content_types = {item['UTTypeIdentifier'] for item in info['UTImportedTypeDeclarations']}
assert len(content_types) == 12
# A Finder-only Quick Look app must never become a file-opening candidate.
assert 'CFBundleDocumentTypes' not in info
# Entitlements are verified at source/CI with Scripts/audit.py; a signed bundle
# can be inspected with codesign separately.
for name, identifier in [('QuickLookPreview', 'com.apple.quicklook.preview'), ('QuickLookThumbnail', 'com.apple.quicklook.thumbnail')]:
    bundle = app / 'Contents/PlugIns' / (name + '.appex')
    assert bundle.is_dir(), f'Missing {name}.appex'
    plist = plistlib.loads((bundle / 'Contents/Info.plist').read_bytes())
    extension = plist['NSExtension']
    assert extension['NSExtensionPointIdentifier'] == identifier
    assert set(extension['NSExtensionAttributes']['QLSupportedContentTypes']) == content_types
    assert (bundle / 'Contents/MacOS' / name).is_file()
assert not list(app.rglob('*.qlgenerator'))
print('macOS bundle verification passed: 12 content types, Preview and Thumbnail extensions embedded')
