#!/bin/bash
set -euo pipefail

APP_PATH="$1"
DMG_PATH="$2"

STAGING_DIR=$(mktemp -d)
trap "rm -rf $STAGING_DIR" EXIT

echo "Creating DMG..."
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create -volname "Joiner" \
    -srcfolder "$STAGING_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

echo "Notarizing DMG..."
xcrun notarytool submit "$DMG_PATH" \
    --apple-id "${APPLE_ID:?Set APPLE_ID env var}" \
    --team-id "${TEAM_ID:?Set TEAM_ID env var}" \
    --password "${APP_SPECIFIC_PASSWORD:?Set APP_SPECIFIC_PASSWORD env var}" \
    --wait

xcrun stapler staple "$DMG_PATH"
echo "DMG created: $DMG_PATH"
