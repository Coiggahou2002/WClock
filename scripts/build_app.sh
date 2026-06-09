#!/bin/bash
# Builds the WorldClock SwiftPM executable and assembles a macOS .app bundle.
#
# Why this exists: we build without Xcode (Command Line Tools only), so there is
# no .xcodeproj to produce an .app. SwiftPM gives us a bare executable; a proper
# menu-bar agent needs a bundle with an Info.plist declaring LSUIElement=true
# (no Dock icon) and a bundle identifier. This script compiles in release mode
# and lays out that bundle by hand.
#
# Usage:
#   ./scripts/build_app.sh              # fast: native arch only (for local use)
#   ./scripts/build_app.sh --universal  # arm64 + x86_64 (for sharing with others)
#
# Note: --universal builds each architecture separately and lipo's them, because
# `swift build --arch a --arch b` needs Xcode's xcbuild, which Command Line Tools
# alone does not provide.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="WorldClock"
BUNDLE_ID="com.rory.worldclock"
APP_DIR="build/${APP_NAME}.app"
UNIVERSAL=0
[ "${1:-}" = "--universal" ] && UNIVERSAL=1

if [ "$UNIVERSAL" -eq 1 ]; then
    echo "==> Building universal (arm64 + x86_64)…"
    swift build -c release --triple arm64-apple-macosx14.0
    swift build -c release --triple x86_64-apple-macosx14.0
    BINARY="build/${APP_NAME}.universal"
    lipo -create -output "$BINARY" \
        ".build/arm64-apple-macosx/release/${APP_NAME}" \
        ".build/x86_64-apple-macosx/release/${APP_NAME}"
    lipo -info "$BINARY"
else
    echo "==> Building (release, native arch)…"
    swift build -c release
    BINARY=".build/release/${APP_NAME}"
fi

echo "==> Assembling ${APP_DIR}…"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "$BINARY" "${APP_DIR}/Contents/MacOS/${APP_NAME}"

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

# Ad-hoc code signature so macOS reliably runs a locally built bundle. NOTE:
# this is NOT a Developer ID signature and is NOT notarized, so on another
# person's Mac Gatekeeper will still warn on first launch (see SHARING.md).
codesign --force --deep --sign - "${APP_DIR}" 2>/dev/null || \
    echo "    (codesign skipped — app will still run for personal use)"

echo "==> Done: ${APP_DIR}"
echo "    Launch with: open \"${APP_DIR}\""
