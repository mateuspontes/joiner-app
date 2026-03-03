#!/bin/bash
set -euo pipefail

APP_PATH="$1"
ZIP_PATH="${APP_PATH%.app}.zip"

echo "Zipping for notarization..."
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Submitting to Apple notary service..."
xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "${APPLE_ID:?Set APPLE_ID env var}" \
    --team-id "${TEAM_ID:?Set TEAM_ID env var}" \
    --password "${APP_SPECIFIC_PASSWORD:?Set APP_SPECIFIC_PASSWORD env var}" \
    --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"

rm "$ZIP_PATH"
echo "Notarization complete."
