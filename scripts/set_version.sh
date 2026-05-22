#!/usr/bin/env bash
set -euo pipefail

# Single source of truth for the Safe Screen version.
#
# Usage:
#   ./scripts/set_version.sh MAJOR.MINOR.PATCH
#
# Writes the new public version to the VERSION file, mirrors it into
# Resources/Info.plist (CFBundleShortVersionString) and increments the
# build number (CFBundleVersion). Never edit VERSION or Info.plist by
# hand - that reintroduces the drift this script exists to prevent.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION_FILE="$ROOT_DIR/VERSION"
PLIST="$ROOT_DIR/Resources/Info.plist"

if [[ $# -ne 1 ]]; then
  printf 'usage: %s MAJOR.MINOR.PATCH\n' "$(basename "$0")" >&2
  exit 1
fi

NEW_VERSION="$1"

if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'Invalid version "%s": expected MAJOR.MINOR.PATCH\n' "$NEW_VERSION" >&2
  exit 1
fi

if [[ ! -f "$PLIST" ]]; then
  printf 'Missing Info.plist at %s\n' "$PLIST" >&2
  exit 1
fi

OLD_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE" 2>/dev/null || echo 'none')"
OLD_BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST")"
NEW_BUILD=$(( OLD_BUILD + 1 ))

printf '%s\n' "$NEW_VERSION" > "$VERSION_FILE"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" "$PLIST"

printf 'version  %s -> %s\n' "$OLD_VERSION" "$NEW_VERSION"
printf 'build    %s -> %s\n' "$OLD_BUILD" "$NEW_BUILD"
printf 'updated  VERSION, Resources/Info.plist\n'
printf '\nnext:\n'
printf '  1. update CHANGELOG.md\n'
printf '  2. git add VERSION Resources/Info.plist CHANGELOG.md\n'
printf '  3. git commit -m "Release v%s"\n' "$NEW_VERSION"
printf '  4. git tag v%s && git push origin main v%s\n' "$NEW_VERSION" "$NEW_VERSION"
