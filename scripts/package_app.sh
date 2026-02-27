#!/usr/bin/env bash
set -euo pipefail

APP_NAME="MacSquak"
BUNDLE_ID="${BUNDLE_ID:-com.sglyon.macsquak}"
TEAM_IDENTITY="${CODESIGN_IDENTITY:--}"   # '-' => ad-hoc
CONFIG="${CONFIG:-release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
APP_DIR="$DIST/${APP_NAME}.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RES="$CONTENTS/Resources"

mkdir -p "$DIST"
rm -rf "$APP_DIR"

pushd "$ROOT" >/dev/null
swift build -c "$CONFIG"
BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)/$APP_NAME"
popd >/dev/null

mkdir -p "$MACOS" "$RES"
cp "$BIN_PATH" "$MACOS/$APP_NAME"
cp "$ROOT/Sources/Resources/transcribe_parakeet.py" "$RES/transcribe_parakeet.py"
chmod +x "$MACOS/$APP_NAME" "$RES/transcribe_parakeet.py"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSMicrophoneUsageDescription</key><string>MacSquak needs microphone access to record speech for local transcription.</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

echo "APPL????" > "$CONTENTS/PkgInfo"

codesign --force --deep --sign "$TEAM_IDENTITY" "$APP_DIR"

echo "✅ Packaged app: $APP_DIR"
echo "Bundle ID: $BUNDLE_ID"
echo "Code signing identity: $TEAM_IDENTITY"
echo "Run with: open '$APP_DIR'"
