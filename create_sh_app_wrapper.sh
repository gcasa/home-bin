#!/usr/bin/env bash
set -euo pipefail

# Creates a macOS .app wrapper around a shell script.
# Usage:
#   ./create_sh_app_wrapper.sh [script_path] [app_name]
#
# Examples:
#   ./create_sh_app_wrapper.sh
#   ./create_sh_app_wrapper.sh ./myscript.sh
#   ./create_sh_app_wrapper.sh ./myscript.sh "My Script App"

INVOKE_DIR="$(pwd)"
SCRIPT_PATH="${1:-}"
APP_NAME="${2:-}"

if [[ -z "$SCRIPT_PATH" ]]; then
  # Pick the first .sh file in the invocation directory if none is provided.
  SCRIPT_PATH="$(find "$INVOKE_DIR" -maxdepth 1 -type f -name "*.sh" | sort | head -n 1)"
  if [[ -z "$SCRIPT_PATH" ]]; then
    echo "No .sh files found in $INVOKE_DIR"
    exit 1
  fi
fi

if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "Shell script not found: $SCRIPT_PATH"
  exit 1
fi

# Resolve to absolute path.
SCRIPT_PATH="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)/$(basename "$SCRIPT_PATH")"

if [[ -z "$APP_NAME" ]]; then
  BASE_NAME="$(basename "$SCRIPT_PATH" .sh)"
  APP_NAME="$BASE_NAME"
fi

APP_BUNDLE="$INVOKE_DIR/${APP_NAME}.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
PLIST_PATH="$CONTENTS_DIR/Info.plist"
LAUNCHER_PATH="$MACOS_DIR/${APP_NAME}"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>local.wrapper.$(echo "$APP_NAME" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9.-')</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>LSMinimumSystemVersion</key>
  <string>10.13</string>
</dict>
</plist>
PLIST

cat > "$LAUNCHER_PATH" <<LAUNCHER
#!/usr/bin/env bash
set -euo pipefail
exec /usr/bin/env bash "$SCRIPT_PATH"
LAUNCHER

chmod +x "$LAUNCHER_PATH"

echo "Created app bundle: $APP_BUNDLE"
echo "Launcher: $LAUNCHER_PATH"