#!/bin/bash
set -euo pipefail

APP_PATH="$1"
IDENTITY="${CODE_SIGN_IDENTITY:-Developer ID Application}"

echo "Signing $APP_PATH with identity: $IDENTITY"
codesign --force --deep --options runtime \
    --sign "$IDENTITY" \
    --entitlements src/Joiner/Resources/Joiner.entitlements \
    "$APP_PATH"

echo "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
echo "Code signing complete."
