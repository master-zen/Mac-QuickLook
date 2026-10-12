from pathlib import Path
import plistlib
import sys
app = Path(sys.argv[1])
assert app.is_dir()
info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
assert len(info["UTImportedTypeDeclarations"]) == 12
for name, point in [("QuickLookPreview", "com.apple.quicklook.preview"), ("QuickLookThumbnail", "com.apple.quicklook.thumbnail")]:
    bundle = app / "Contents/PlugIns" / (name + ".appex")
    assert bundle.is_dir(), f"Missing {name}"
    data = plistlib.loads((bundle / "Contents/Info.plist").read_bytes())
    assert data["NSExtension"]["NSExtensionPointIdentifier"] == point
    assert len(data["NSExtension"]["NSExtensionAttributes"]["QLSupportedContentTypes"]) == 12
    assert (bundle / "Contents/MacOS" / name).is_file()
