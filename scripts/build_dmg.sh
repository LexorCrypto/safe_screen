#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CONFIGURATION="${CONFIGURATION:-release}"
APP_NAME="Safe Screen"
APP_DIR="${APP_DIR:-$ROOT_DIR/build/${APP_NAME}.app}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Resources/Info.plist")"
DMG_NAME="${DMG_NAME:-Safe-Screen-${VERSION}.dmg}"
DMG_PATH="${DMG_PATH:-$DIST_DIR/$DMG_NAME}"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/safe-screen-dmg.XXXXXX")"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

APP_DIR="$APP_DIR" CONFIGURATION="$CONFIGURATION" "$ROOT_DIR/scripts/build_app.sh"

rm -f "$DMG_PATH"
mkdir -p "$DIST_DIR"
cp -R "$APP_DIR" "$STAGING_DIR/${APP_NAME}.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_PATH" >/dev/null

hdiutil verify "$DMG_PATH" >/dev/null

printf 'Built %s\n' "$DMG_PATH"
