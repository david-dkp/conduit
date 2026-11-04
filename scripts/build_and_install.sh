#!/usr/bin/env bash
set -euo pipefail

echo "==> Building APK..."
flutter build apk

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
  echo "Error: $APK_PATH not found."
  exit 1
fi

echo "==> Checking for connected devices..."
# Connect to wireless debugging device if mdns service is discovered
DISCOVERED_DEVICE=$(adb mdns services 2>/dev/null | grep "_adb-tls-connect" | awk '{print $3}' | head -n 1 || true)
if [ -n "$DISCOVERED_DEVICE" ]; then
  adb connect "$DISCOVERED_DEVICE" >/dev/null 2>&1 || true
fi

DEVICE_ID=$(adb devices | grep -v "List" | grep "device$" | awk '{print $1}' | head -n 1 || true)

if [ -n "$DEVICE_ID" ]; then
  echo "==> Installing to device $DEVICE_ID..."
  adb -s "$DEVICE_ID" install -r "$APK_PATH"
  echo "==> Launching app..."
  adb -s "$DEVICE_ID" shell am start -n app.cogwheel.conduit/.MainActivity
  echo "==> Done! App is installed and running."
else
  echo "No adb device connected. The APK is ready at: $APK_PATH"
fi
