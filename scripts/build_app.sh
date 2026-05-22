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

VERSION_FILE="$ROOT_DIR/VERSION"
if [[ ! -f "$VERSION_FILE" ]]; then
  printf 'Missing VERSION file at %s\n' "$VERSION_FILE" >&2
  exit 1
fi
VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"

cp "$BIN_DIR/SafeScreenApp" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_DIR/Contents/Info.plist"
swift "$ROOT_DIR/scripts/generate_icon.swift" "$APP_DIR/Contents/Resources/SafeScreen.icns"

chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

# The repo may live in a FileProvider-synced folder (iCloud / Documents),
# whose daemon re-applies com.apple.FinderInfo xattrs onto the bundle.
# That races with codesign ("resource fork ... not allowed"). Clear
# xattrs, sign and verify as one unit, and retry if the race bites.
sign_and_verify() {
  xattr -cr "$APP_DIR" 2>/dev/null || true
  codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || return 1
  codesign --verify --deep --strict "$APP_DIR" 2>/dev/null || return 1
}

signed=0
for attempt in 1 2 3; do
  if sign_and_verify; then
    signed=1
    break
  fi
  printf 'codesign attempt %d hit the FileProvider xattr race, retrying...\n' "$attempt" >&2
  sleep 1
done

if [[ "$signed" -ne 1 ]]; then
  printf 'codesign failed after 3 attempts on %s\n' "$APP_DIR" >&2
  exit 1
fi

printf 'Built %s\n' "$APP_DIR"
