#!/bin/bash
# File: wrap-noncocoa.sh

set -e

if [ $# -lt 2 ]; then
  echo "Usage: $0 <binary_path> <AppName> [--wine]"
  echo "  --wine: Treat binary as a Wine executable"
  exit 1
fi

BINARY_PATH="$(realpath "$1")"
APP_NAME="$2"
WINE_MODE=false

# Check for wine flag
if [ "$3" = "--wine" ] || [[ "$1" == *.exe ]]; then
  WINE_MODE=true
fi

APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
BINARY_NAME="$(basename "$BINARY_PATH")"

# Create bundle structure
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Copy the binary into the app bundle
if [ -f "$BINARY_PATH" ]; then
  cp "$BINARY_PATH" "$RESOURCES_DIR/$BINARY_NAME"
  chmod +x "$RESOURCES_DIR/$BINARY_NAME"
  echo "Copied binary to app bundle: $BINARY_NAME"
else
  echo "Error: Binary not found at $BINARY_PATH"
  exit 1
fi

# Create launcher script based on binary type
if [ "$WINE_MODE" = true ]; then
  # Wine executable launcher
  cat > "${MACOS_DIR}/launcher" <<EOF
#!/bin/bash
# Launches Wine executable inside Terminal
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="\$SCRIPT_DIR/../Resources"
WINE_BINARY="\$RESOURCES_DIR/$BINARY_NAME"

if command -v wine >/dev/null 2>&1; then
  cd "\$RESOURCES_DIR"
  open -a Terminal --args bash -c "wine '\$WINE_BINARY'; read -p 'Press Enter to close...'"
else
  osascript -e 'display alert "Wine Not Found" message "Wine is required to run this application. Please install Wine first." buttons {"OK"} default button "OK"'
fi
EOF
else
  # Regular binary launcher
  cat > "${MACOS_DIR}/launcher" <<EOF
#!/bin/bash
# Launches wrapped binary inside Terminal
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="\$SCRIPT_DIR/../Resources"
BINARY="\$RESOURCES_DIR/$BINARY_NAME"

cd "\$RESOURCES_DIR"
open -a Terminal --args bash -c "'\$BINARY'; read -p 'Press Enter to close...'"
EOF
fi

chmod +x "${MACOS_DIR}/launcher"

# Create Info.plist
cat > "${CONTENTS_DIR}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
 <dict>
   <key>CFBundleName</key>
   <string>${APP_NAME}</string>
   <key>CFBundleExecutable</key>
   <string>launcher</string>
   <key>CFBundleIdentifier</key>
   <string>com.example.${APP_NAME}</string>
   <key>CFBundlePackageType</key>
   <string>APPL</string>
   <key>CFBundleSignature</key>
   <string>????</string>
   <key>CFBundleVersion</key>
   <string>1.0</string>
 </dict>
</plist>
EOF

# Set appropriate icon based on binary type
if [ "$WINE_MODE" = true ]; then
  echo "Created Wine-enabled ${APP_BUNDLE}"
  echo "Note: Wine must be installed to run this application"
else
  echo "Created ${APP_BUNDLE}"
fi

echo "Binary copied to: ${RESOURCES_DIR}/${BINARY_NAME}"
