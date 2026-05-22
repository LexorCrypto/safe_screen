#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CONFIGURATION="${CONFIGURATION:-release}"
APP_NAME="Safe Screen"
APP_DIR="${APP_DIR:-$ROOT_DIR/build/${APP_NAME}.app}"

if [[ "$(basename "$APP_DIR")" != "${APP_NAME}.app" ]]; then
  printf 'Refusing to build unexpected app path: %s\n' "$APP_DIR" >&2
  exit 1
fi

swift build -c "$CONFIGURATION" --product SafeScreenApp
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$(dirname "$APP_DIR")"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BIN_DIR/SafeScreenApp" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
swift "$ROOT_DIR/scripts/generate_icon.swift" "$APP_DIR/Contents/Resources/SafeScreen.icns"

chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"
xattr -cr "$APP_DIR" 2>/dev/null || true
codesign --force --deep --sign - "$APP_DIR" >/dev/null
xattr -cr "$APP_DIR" 2>/dev/null || true
codesign --verify --deep --strict --verbose=2 "$APP_DIR" >/dev/null

printf 'Built %s\n' "$APP_DIR"
