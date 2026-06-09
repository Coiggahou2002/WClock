#!/bin/bash
# Builds the WorldClock SwiftPM executable and assembles a macOS .app bundle.
#
# Why this exists: we build without Xcode (Command Line Tools only), so there is
# no .xcodeproj to produce an .app. SwiftPM gives us a bare executable; a proper
# menu-bar agent needs a bundle with an Info.plist declaring LSUIElement=true
# (no Dock icon, no menu bar app menu) and a bundle identifier. This script
# compiles in release mode and lays out that bundle by hand.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="WorldClock"
BUNDLE_ID="com.rory.worldclock"
BUILD_DIR=".build/release"
APP_DIR="build/${APP_NAME}.app"

echo "==> Building (release)…"
swift build -c release

echo "==> Assembling ${APP_DIR}…"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"

cat > "${APP_DIR}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>World Clock</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# Ad-hoc code signature so macOS reliably runs a locally built bundle and the
# menu-bar item appears without Gatekeeper interference.
codesign --force --deep --sign - "${APP_DIR}" 2>/dev/null || \
    echo "    (codesign skipped — app will still run for personal use)"

echo "==> Done: ${APP_DIR}"
echo "    Launch with: open \"${APP_DIR}\""
