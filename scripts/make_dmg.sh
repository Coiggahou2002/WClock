#!/bin/bash
# Packages WorldClock.app into a distributable disk image (WorldClock.dmg) with
# a drag-to-Applications layout — the familiar "download, double-click, drag in"
# install flow used by indie Mac apps (Maccy, etc.).
#
# The DMG is just a container: it does NOT change Gatekeeper's verdict. Because
# this build is ad-hoc signed (not Developer ID + notarized), recipients still
# get a one-time security warning on first launch. See SHARING.md for the steps
# they follow, and ADR-0001 for why notarization is out of scope here.
#
# Uses the built-in `hdiutil` (no Homebrew/create-dmg needed). Builds a
# universal (arm64 + x86_64) app so it runs on both Apple Silicon and Intel.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="WorldClock"
VOL_NAME="World Clock"
APP_DIR="build/${APP_NAME}.app"
DMG_PATH="build/${APP_NAME}.dmg"
STAGE_DIR="build/dmg-stage"

# 1) Build the universal app bundle.
./scripts/build_app.sh --universal

# 2) Stage the app + an Applications symlink (drag target).
echo "==> Staging DMG contents…"
rm -rf "${STAGE_DIR}" "${DMG_PATH}"
mkdir -p "${STAGE_DIR}"
cp -R "${APP_DIR}" "${STAGE_DIR}/"
ln -s /Applications "${STAGE_DIR}/Applications"

# 3) Build a compressed read-only DMG from the staging folder.
echo "==> Creating ${DMG_PATH}…"
hdiutil create \
    -volname "${VOL_NAME}" \
    -srcfolder "${STAGE_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}" >/dev/null

rm -rf "${STAGE_DIR}"

echo "==> Done: ${DMG_PATH}"
echo "    Size: $(du -h "${DMG_PATH}" | cut -f1)"
echo "    Send this file to friends along with SHARING.md."
