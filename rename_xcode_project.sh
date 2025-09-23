#!/usr/bin/env bash
# File: rename_xcode_project.sh
# Usage: ./rename_xcode_project.sh <old_name> <new_name> <project_path>

set -euo pipefail

OLD_NAME="$1"
NEW_NAME="$2"
PROJECT_PATH="$3"

XCODEPROJ_PATH="$PROJECT_PATH/$OLD_NAME.xcodeproj"
PBXPROJ_FILE="$XCODEPROJ_PATH/project.pbxproj"

if [[ ! -d "$XCODEPROJ_PATH" ]]; then
  echo "❌ Project not found: $XCODEPROJ_PATH"
  exit 1
fi

echo "🔄 Renaming project from $OLD_NAME to $NEW_NAME"

# Backup and replace in project.pbxproj
cp "$PBXPROJ_FILE" "$PBXPROJ_FILE.bak"
sed -i '' "s/$OLD_NAME/$NEW_NAME/g" "$PBXPROJ_FILE"

# Handle scheme files
SCHEMES_DIR="$XCODEPROJ_PATH/xcshareddata/xcschemes"
if [[ -d "$SCHEMES_DIR" ]]; then
  for SCHEME in "$SCHEMES_DIR"/*.xcscheme; do
    if [[ -f "$SCHEME" ]]; then
      cp "$SCHEME" "$SCHEME.bak"
      sed -i '' "s/$OLD_NAME/$NEW_NAME/g" "$SCHEME"
      if [[ "$SCHEME" == *"$OLD_NAME"* ]]; then
        NEW_SCHEME="${SCHEME//$OLD_NAME/$NEW_NAME}"
        mv "$SCHEME" "$NEW_SCHEME"
      fi
    fi
  done
fi

# Rename .xcodeproj folder
NEW_XCODEPROJ_PATH="$PROJECT_PATH/$NEW_NAME.xcodeproj"
mv "$XCODEPROJ_PATH" "$NEW_XCODEPROJ_PATH"

# Rename .entitlements file
NEW_ENTITLEMENTS="$PROJECT_PATH/NEW_NAME.entitlements"
OLD_ENTITLEMENTS="$PROJECT_PATH/OLD_NAME.entitlements"
if [[ -e "$OLD_ENTITLEMENTS" ]]; then
  mv $OLD_ENTITLEMENTS $NEW_ENTITLEMENTS
fi

# Rename project source folder if it matches old name
if [[ -d "$PROJECT_PATH/$OLD_NAME" ]]; then
  mv "$PROJECT_PATH/$OLD_NAME" "$PROJECT_PATH/$NEW_NAME"
fi

echo "✅ Renamed project to $NEW_NAME"
