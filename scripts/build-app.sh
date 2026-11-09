#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"
swift build -c release --disable-sandbox --build-system native
APP="$PWD/dist/Guilty.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swift scripts/make-icon.swift "$PWD/Assets"
cp Assets/Guilty.icns "$APP/Contents/Resources/Guilty.icns"
cp .build/release/Guilty "$APP/Contents/MacOS/Guilty"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Guilty</string>
<key>CFBundleDisplayName</key><string>Guilty</string>
<key>CFBundleIdentifier</key><string>app.guilty.focus</string>
<key>CFBundleExecutable</key><string>Guilty</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundleVersion</key><string>3</string>
<key>CFBundleIconFile</key><string>Guilty.icns</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSAppleEventsUsageDescription</key><string>Guilty reads the active browser tab address to spot blocked entertainment websites during your focus timer.</string>
</dict></plist>
PLIST
xattr -d com.apple.FinderInfo "$APP" 2>/dev/null || true
codesign --force --deep --sign - "$APP"
touch "$APP"
echo "Built $APP"
