#!/bin/bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
python3 Scripts/audit.py
swift test --jobs 2
swiftc -frontend -parse App/MacQuickLookModernApp.swift Extensions/Preview/PreviewProvider.swift Extensions/Thumbnail/ThumbnailProvider.swift
