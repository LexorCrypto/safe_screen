#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${APP_DIR:-/Applications/Safe Screen.app}"

osascript -e 'tell application id "com.lexor.SafeScreen" to quit' >/dev/null 2>&1 || true
sleep 0.5

APP_DIR="$APP_DIR" "$ROOT_DIR/scripts/build_app.sh"

printf 'Installed %s\n' "$APP_DIR"
