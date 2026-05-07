#!/usr/bin/env bash
set -euo pipefail

flutter pub get
dart run flutter_native_splash:create
flutter build apk --debug

echo "APK created at: build/app/outputs/flutter-apk/app-debug.apk"
