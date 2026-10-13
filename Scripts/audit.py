from pathlib import Path
import csv
import plistlib
import re

root = Path(__file__).resolve().parent.parent
app = plistlib.loads((root / 'App/Info.plist').read_bytes())
preview = plistlib.loads((root / 'Extensions/Preview/Info.plist').read_bytes())
thumb = plistlib.loads((root / 'Extensions/Thumbnail/Info.plist').read_bytes())
ids = {row['UTTypeIdentifier'] for row in app['UTImportedTypeDeclarations']}
assert len(ids) == 12, f'Unexpected number of UTTypes: {len(ids)}'
assert app['NSPrincipalClass'] == 'NSApplication'
assert app['LSMinimumSystemVersion'] == '13.0'
entitlements = plistlib.loads((root / 'App/Entitlements.plist').read_bytes())
assert entitlements['com.apple.security.app-sandbox'] is True
assert 'com.apple.security.files.user-selected.read-only' not in entitlements
# Metadata-only Launch Services registration must NEVER claim file opening.
# CFBundleTypeRole=None means the host cannot operate on these documents.
docs = app['CFBundleDocumentTypes']
assert len(docs) == len(ids)
assert {uti for item in docs for uti in item['LSItemContentTypes']} == ids
assert all(item['CFBundleTypeRole'] == 'None' and item['LSHandlerRank'] == 'None' for item in docs)
host_source = (root / 'App/MacQuickLookModernApp.swift').read_text()
for forbidden in ['NSOpenPanel', 'DocumentGroup(', 'fileImporter(', 'FileSummary.read(', 'startAccessingSecurityScopedResource']:
    assert forbidden not in host_source, f'Quick Look-only host must not use {forbidden}'
for plist in [preview, thumb]:
    ext = plist['NSExtension']
    supported = ext['NSExtensionAttributes']['QLSupportedContentTypes']
    assert set(supported) == ids and len(supported) == len(ids)
    assert ext['NSExtensionPointIdentifier'] in ['com.apple.quicklook.preview', 'com.apple.quicklook.thumbnail']
assert preview['NSExtension']['NSExtensionAttributes']['QLIsDataBasedPreview'] is True
assert set(x['UTTypeIdentifier'] for x in app['UTImportedTypeDeclarations']) == ids
assert thumb['NSExtension']['NSExtensionAttributes']['QLThumbnailMinimumDimension'] == 32
swift = (root / 'Shared/FileSummary.swift').read_text()
for id in ids:
    ext = id.rsplit('.', 1)[1]
    assert re.search(r'case\s+"' + re.escape(ext) + r'"', swift)
files = list(root.rglob('*'))
assert not any(p.is_dir() and p.name.lower().endswith('.qlgenerator') for p in files)
assert not any(p.suffix.lower() == '.pkg' for p in files)
with (root / 'Docs/LEGACY_INVENTORY.csv').open() as stream:
    legacy = list(csv.DictReader(stream))
assert len(legacy) == 87
assert len([x for x in legacy if x['source_kind'] == 'legacy-plugin']) == 76
assert len([x for x in legacy if x['source_kind'] == 'legacy-installer']) == 11
print(f'Audit passed: {len(ids)} content types, {len(legacy)} legacy inventory entries, two Quick Look extensions.')
