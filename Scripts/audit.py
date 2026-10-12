from pathlib import Path
import plistlib

root = Path(__file__).resolve().parent.parent
app = plistlib.loads((root / "App/Info.plist").read_bytes())
ids = {x["UTTypeIdentifier"] for x in app["UTImportedTypeDeclarations"]}
assert len(ids) == 12
assert app["LSMinimumSystemVersion"] == "13.0"
assert ids == {x for item in app["CFBundleDocumentTypes"] for x in item["LSItemContentTypes"]}
for folder, kind in [("Preview", "com.apple.quicklook.preview"), ("Thumbnail", "com.apple.quicklook.thumbnail")]:
    ext = plistlib.loads((root / "Extensions" / folder / "Info.plist").read_bytes())["NSExtension"]
    assert ext["NSExtensionPointIdentifier"] == kind
    assert set(ext["NSExtensionAttributes"]["QLSupportedContentTypes"]) == ids
assert not list(root.rglob("*.qlgenerator"))
assert not list(root.rglob("*.pkg"))
print("12 declared UTIs, 2 embedded Quick Look extensions, no legacy installers")
