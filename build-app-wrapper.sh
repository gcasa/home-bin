#!/bin/sh

APP="$1"
EXEC="$2"

echo "=== Building $APP"

# Build Cocoa application wrapper
mkdir -p "$APP"/Contents/MacOS
cp "$EXEC" "$APP"/Contents/MacOS/

# Build Info.plist
cat > "$APP"/Contents/MacOS/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$EXEC</string>
    <key>CFBundleIconFile</key>
    <string>icon.icns</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.$EXEC</string>
    <key>CFBundleName</key>
    <string>$EXEC</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
</dict>
</plist>
EOF

echo "=== Done building $APP"
exit 0