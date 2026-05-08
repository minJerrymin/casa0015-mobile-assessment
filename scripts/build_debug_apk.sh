#!/usr/bin/env bash
set -euo pipefail

if [ ! -d android ]; then
  flutter create --platforms=android .
fi
python3 scripts/patch_android_permissions.py
flutter pub get
dart run flutter_native_splash:create
flutter build apk --debug

echo "APK created at: build/app/outputs/flutter-apk/app-debug.apk"
